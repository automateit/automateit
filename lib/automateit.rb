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
      @interpreter = opts[:interpreter]
    end

    def omfg(*args)
      "omfg"
    end
  end

  class Interpreter < Common
    attr_accessor :parent

    def setup(opts={})
      super(opts.merge(:interpreter => self))

      if opts[:parent]
        @parent = opts[:parent]
      end

      if opts[:logger]
        @logger = opts[:logger]
      elsif not defined?(@logger) or @logger.nil?
          @logger = Logger.new(STDOUT)
          @logger.level = Logger::INFO
      end

      unless opts[:logger_level].nil?
        @logger.level = opts[:logger_level]
      end

      if opts[:noop].nil?
        unless defined?(@noop)
          @noop = false
        end
      else
        @noop = opts[:noop]
      end

      instantiate_plugins
      expose_plugins
    end

    attr_accessor :plugins

    def instantiate_plugins
      @plugins ||= {}
      if defined?(@parent) and @parent and @parent.is_a?(Plugin::Manager)
        plugins[@parent.class.token] = @parent
      end
      AutomateIt::Plugin::Manager.classes.reject{|t|t==@parent if @parent}.each do |plugin_class|
        plugin_token = plugin_class.token

        if plugin = @plugins[plugin_token]
          plugin.instantiate_drivers
        else
          @plugins[plugin_token] = plugin_class.new(:interpreter=> self)
        end
      end
    end

    def expose_plugin_instances
      @plugins.each_pair do |token, plugin|
        unless methods.include?(token.to_s)
          self.class.send(:define_method, token) do
            @plugins[token]
          end
        end
      end
    end

    def expose_plugin_methods
      @plugins.values.each do |plugin|
        next unless plugin.class.aliased_methods
        plugin.class.aliased_methods.each do |method|
          unless methods.include?(method.to_s)
            self.class.send(:define_method, method) do |*args|
              @plugins[plugin.class.token].send(method, *args)
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

        # TODO How to ensure that the same objects are shared when either the Manager, Plugin or Interpreter is instantiated?
        #puts "base self: #{self} // interpreter #{@interpreter}"
        @interpreter = AutomateIt::Interpreter.new(:parent => self) unless @interpreter
      end

      def token
        self.class.token
      end

      def self.token
        return to_s.demodulize.underscore.to_sym
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

      class_inheritable_accessor :aliased_methods

      # Methods to alias into +Interpreter+, specified as an array of symbols.
      def self.alias_methods(*args)
        if args.empty?
          self.aliased_methods
        else
          self.aliased_methods ||= Set.new
          self.aliased_methods.merge(args.flatten)
        end
      end

      attr_accessor :drivers

      # +Driver+ classes used by this +Manager+
      def self.driver_classes
        Driver.classes.select{|driver|driver.to_s.match(/^#{self}::/)}
      end

      def setup(opts={})
        super(opts)
        instantiate_drivers

        if driver = opts[:default] || opts[:driver]
          default(opts[:default]) if opts[:default]
          @drivers[driver].setup(opts)
        end
      end

      def instantiate_drivers
        @drivers ||= {}
        self.class.driver_classes.each do |driver_class|
          driver_token = driver_class.token
          unless @drivers[driver_token]
            driver = @drivers[driver_token] = driver_class.new(:interpreter => @interpreter)
          end
        end
      end

      # Returns token for this +Manager+ as a symbol. E.g. the token for +TagManager+ is +:tag_manager+.
      def token
        return self.class.token
      end

      # Returns the +Driver+ with the specified token. E.g. +:apt+ will return the +APT+ driver.
      def [](token)
        return @drivers[token]
      end

      # Manipulate the default driver. Without arguments, gets the driver token as a symbol. With argument, sets the default driver to the +token+, e.g. the argument +:apt+ will make the +APT+ driver the default.
      def default(token=nil)
        if token.nil?
          return defined?(@default) ? @default : nil
        else
          @default = token
        end
      end

      def default=(token)
        default(token)
      end

      def dispatch(*args, &block)
        # Extract caller's method as symbol to save user from having to specify it
        method = caller[0].match(/:in `(.+?)'/)[1].to_sym
        dispatch_to(method, *args, &block)
      end

      def dispatch_to(method, *args, &block)
        if default
          @drivers[default].send(method, *args, &block)
        else
          driver_for(method, *args, &block).send(method, *args, &block)
        end
      end

      def driver_suitability_levels_for(method, *args, &block)
        results = {}
        @drivers.each_pair do |name, driver|
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
          return @drivers[driver]
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

  class FieldManager < Plugin::Manager
    alias_methods :lookup

    def lookup(query)
      dispatch(query)
    end

    class Struct < Plugin::Driver
      attr_accessor :struct

      def suitability(method, *args)
        return 1
      end

      def setup(opts={})
        super(opts)
        if opts[:struct]
          @struct = opts[:struct]
        end
      end

      def lookup(query)
        ref = @struct
        for key in query.to_s.split("#")
          ref = ref[key]
        end
        ref
      end
    end

    require 'erb'
    require 'yaml'
    class YAML < Struct
      def suitability(method, *args)
        return 5
      end

      def setup(opts={})
        super(opts)
        if opts[:file]
          @struct = ::YAML::load(ERB.new(File.read(opts[:file]), nil, '-').result)
        end
      end

    end

  end

end
