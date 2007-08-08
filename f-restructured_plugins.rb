#!/usr/bin/env ruby

# TODO include selections from the "b" branch of interpreter
# TODO rename stuff to match new naming conventions

# TODO add logic to guess project path
# TODO add Environment

require 'rubygems'
require 'active_support'
require 'set'
require 'logger'

# RDoc about AutomateIt
module AutomateIt #:main: AutomateIt

  # All actual methods are in the included module +CommonLib+.
  class Common
    attr_accessor :interpreter

    def initialize(opts={})
      setup(opts)
    end

    def setup(opts={})
      self.interpreter = opts[:interpreter]
    end

    def omfg(*args)
      "omfg"
    end
  end

  class Interpreter < Common
    def setup(opts={})
      super(opts.merge(:interpreter => self))
      instantiate_plugins
      expose_plugins

      if opts[:logger]
        self.logger = opts[:logger]
      elsif logger.nil?
          self.logger = Logger.new(STDOUT)
          self.logger.level = Logger::INFO
      end

      unless opts[:logger_level].nil?
        self.logger.level = opts[:logger_level]
      end

      if opts[:noop].nil?
        unless defined?(@noop)
          self.noop = false
        end
      else
        self.noop = opts[:noop]
      end
    end

    attr_accessor :plugins

    def instantiate_plugins
      self.plugins ||= {}
      AutomateIt::Plugin::Manager.classes.each do |plugin_class|
        plugin_token = plugin_class.token

        if plugin = plugins[plugin_token]
          plugin.instantiate_drivers
        else
          plugins[plugin_token] = plugin_class.new(:interpreter=> self)
        end
      end
    end

    def expose_plugin_instances
      plugins.each_pair do |token, plugin|
        unless methods.include?(token.to_s)
          self.class.send(:define_method, token) do
            plugins[token]
          end
        end
      end
    end

    def expose_plugin_methods
      plugins.values.each do |plugin|
        next unless plugin.class.aliased_methods
        plugin.class.aliased_methods.each do |method|
          unless methods.include?(method.to_s)
            self.class.send(:define_method, method) do |*args|
              plugins[plugin.class.token].send(method, *args)
            end
          end
        end
      end
    end

    def expose_plugins
      expose_plugin_instances
      expose_plugin_methods
    end

    attr_writer :logger
    def logger(value=nil)
      if value.nil?
        return defined?(@logger) ? @logger : nil
      else
        @logger = value
      end
    end

    attr_writer :noop
    def noop(value)
      @noop = value
    end

    def noop?(&block)
      if @noop and block
        block.call
      else
        @noop
      end
    end

    def writing(value)
      self.writing = value
    end

    def writing=(value)
      @noop = !value
    end

    def writing?(message=nil, &block)
      if !@noop and block
        block.call
      else
        !@noop
      end
    end

  end

  class Plugin

    class Base < Common
      def setup(opts={})
        super(opts)
        self.interpreter = AutomateIt::Interpreter.new unless interpreter
      end

      def self.token
        return self.to_s.demodulize.underscore.to_sym
      end

      def self.collect_registrations
        cattr_accessor :classes

        self.classes = Set.new

        def self.inherited(subclass)
          classes << subclass
        end

        def self.abstract_plugin
          classes.delete(self)
        end
      end
    end

    class Manager < Base
      collect_registrations

      def setup(opts={})
        super(opts)
        instantiate_drivers
      end

      def instantiate_drivers
        self.drivers ||= {}
        self.class.driver_classes.each do |driver_class|
          driver_token = driver_class.token
          unless drivers[driver_token]
            driver = drivers[driver_token] = driver_class.new(:interpreter => interpreter)
          end
        end
      end

      def token
        return self.class.token
      end

      attr_accessor :drivers

      def [](key)
        return self.drivers[key]
      end

      # Get or set the default driver token. Without arguments, gets the driver token. With arguments, sets the +token+, e.g. +my_driver+ is the token for the +MyDriver+ class.
      def default(token=nil)
        if token.nil?
          return defined?(@default) ? @default : nil
        else
          @default = token
        end
      end

      class_inheritable_accessor :aliased_methods

      def self.alias_methods(*args)
        self.aliased_methods ||= Set.new
        self.aliased_methods.merge(args)
      end

      def self.driver_classes
        Driver.classes.select{|driver|driver.to_s.match(/^#{self}::/)}
      end

      def dispatch(method, *args, &block)
        if default
          drivers[default].send(method, *args, &block)
        else
          driver_for(method, *args, &block).send(method, *args, &block)
        end
      end

      def driver_suitability_levels_for(method, *args, &block)
        results = {}
        drivers.each_pair do |name, driver|
          next unless driver.respond_to?(method)
          results[name] = driver.suitability(method, *args, &block)
        end
        return results
      end

      def driver_for(method, *args, &block)
        begin
          driver, level = driver_suitability_levels_for(method, *args, &block).sort_by{|k,v| v}.last
        rescue IndexError
          driver = nil
          level = -1
        end
        if driver and level > 0
          return drivers[driver]
        else
          raise ArgumentError.new("can't find driver for method '#{method}' with arguments: #{args.inspect}")
        end
      end
    end

    class Driver < Base
      collect_registrations

      def suitability(method, *args, &block)
        # TODO log.warn("driver author forgot to implement suitability method in #{self.class}")
        #raise NotImplementedError.new("driver author forgot to implement suitability method in #{self.class}")
        return -1
      end
    end

  end

end

#===[ stub classes ]====================================================

class MyManager < AutomateIt::Plugin::Manager
  alias_methods :mymethod

  def mymethod(opts)
    dispatch(:mymethod, opts)
  end
end

class MyManager::MyUnsuitableDriver < AutomateIt::Plugin::Driver
  # +suitability+ method deliberately not implemented
end

class MyManager::MyUnimplementedDriver < AutomateIt::Plugin::Driver
  def suitability(method, *args)
    return 50
  end
  # +mymethod+ method deliberately not implemented
end


class MyManager::MyFirstDriver < AutomateIt::Plugin::Driver
  def suitability(method, *args)
    case method
    when :mymethod
      return args.first[:one] == 1 ? 10 : 0
    else
      return -1
    end
  end
  def mymethod(opts)
    opts[:one]
  end
end

class MyManager::MySecondDriver < AutomateIt::Plugin::Driver
  def suitability(method, *args)
    case method
    when :mymethod
      return args.first[:one] == 1 ? 5 : 0
    else
      return -1
    end
  end
  def mymethod(opts)
    opts[:one]
  end
end

class MyManagerSubclass < AutomateIt::Plugin::Manager
  abstract_plugin
end

class MyManagerSubclassImplementation < MyManagerSubclass
end

#===[ rspec ]===========================================================

describe AutomateIt::Plugin::Manager do
  before do
    @x = AutomateIt::Plugin::Manager
  end

  it "should have plugins" do
    @x.classes.include?(MyManager).should be_true
  end

  it "should not have abstract plugins" do
    @x.classes.include?(MyManagerSubclass).should be_false
  end

  it "should have implementations of abstract plugins" do
    @x.classes.include?(MyManagerSubclassImplementation).should be_true
  end
end

describe MyManager do
  it "should have drivers" do
    for driver in [MyManager::MyUnsuitableDriver, MyManager::MyFirstDriver, MyManager::MySecondDriver]
      MyManager.driver_classes.include?(driver)
    end
  end

  it "should inherit common instance mehtods" do
    MyManager.new.should respond_to(:omfg)
  end

  it "should access drivers by index keys" do
    m = MyManager.new
    m[:my_first_driver].is_a?(MyManager::MyFirstDriver).should be_true
    m.drivers[:my_first_driver].is_a?(MyManager::MyFirstDriver).should be_true
  end

  it "should have aliased methods" do
    MyManager.aliased_methods.include?(:mymethod).should be_true
  end

  it "should respond to aliased methods" do
    MyManager.new.should respond_to(:mymethod)
  end

  it "should have an interpreter instance" do
    MyManager.new.interpreter.is_a?(AutomateIt::Interpreter).should be_true
  end

  it "should inject interpreter instance into drivers" do
    m = MyManager.new
    m.interpreter.should == m[:my_first_driver].interpreter
  end
end

describe "MyManager drivers" do
  it "should have a token" do
    MyManager::MyFirstDriver.token.should == :my_first_driver
  end

  it "should consider good drivers to be suitable" do
    MyManager::MyFirstDriver.new.suitability(:mymethod, :one => 1).should > 0
  end

  it "should not consider drivers that don't declare their suitability" do
    MyManager::MyUnsuitableDriver.new.suitability(:mymethod, :one => 1).should < 0
  end

  it "should determine suitability levels" do
    m = MyManager.new
    rs = m.driver_suitability_levels_for(:mymethod, :one => 1)
    #rs[:my_first_driver].should == 10
    rs[:my_first_driver].should eql?(10)
    rs[:my_second_driver].should eql?(5)
    rs[:my_unsuitable_driver].should be_nil
  end

  it "should choose suitable driver" do
    MyManager.new.driver_for(:mymethod, :one => 1).is_a?(MyManager::MyFirstDriver).should be_true
  end

  it "should not choose driver if none match" do
    lambda { MyManager.new.driver_for(:mymethod, :one => 9) }.should raise_error(ArgumentError)
  end

  it "should dispatch to suitable driver" do
    m = MyManager.new
    m.dispatch(:mymethod, :one => 1).should eql?(1)
    m.mymethod(:one => 1).should eql?(1)
  end

  it "should fail to dispatch if no suitable driver is found" do
    m = MyManager.new
    lambda { m.dispatch(:mymethod, :one => 9) }.should raise_error(ArgumentError)
    lambda { m.mymethod(:one => 9) }.should raise_error(ArgumentError)
  end

  it "should dispatch to default driver regardless of suitability" do
    m = MyManager.new
    m.default(:my_unimplemented_driver)
    lambda { m.dispatch(:mymethod, :one => 1) }.should raise_error(NoMethodError)
    lambda { m.mymethod(:one => 1) }.should raise_error(NoMethodError)
  end

  it "should have an interpreter instance" do
    MyManager::MyFirstDriver.new.interpreter.is_a?(AutomateIt::Interpreter).should be_true
  end
end

describe AutomateIt::Interpreter do
  before do
    @a = AutomateIt::Interpreter.new
  end

  it "should instantiate plugins" do
    @a.should respond_to(:plugins)
    @a.plugins.include?(:my_manager).should be_true
  end

  it "should expose plugin instance aliases" do
    @a.should respond_to(:my_manager)
    @a.my_manager.class.should == MyManager
  end

  it "should expose plugin method aliases" do
    @a.should respond_to(:mymethod)
    lambda {@a.mymethod(:one => 1)}.should_not raise_error
  end

  it "should inject itself into plugins" do
    @a.my_manager.interpreter.should equal?(@a)
  end

  it "should inject itself into drivers" do
    @a.my_manager[:my_first_driver].interpreter.should equal?(@a)
  end

  it "should have a logger" do
    @a.logger.is_a?(Logger)
  end

  it "should have noop (dryrun) detection" do
    @a.noop = true
    @a.noop?.should be_true
    @a.noop?{9}.should eql?(9)
    @a.writing?.should be_false
    @a.writing?{9}.should be_false

    @a.writing(true)
    @a.noop?.should be_false
    @a.noop?{9}.should be_false
    @a.writing?.should be_true
    @a.writing?{9}.should eql?(9)
  end
end
