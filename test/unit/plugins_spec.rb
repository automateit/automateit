require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

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
