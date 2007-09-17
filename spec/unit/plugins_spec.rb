require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

#===[ stub classes ]====================================================# {{{

class MyManager < AutomateIt::Plugin::Manager
  alias_methods :mymethod

  def mymethod(opts)
    dispatch(opts)
  end
end

class MyManager::BaseDriver < AutomateIt::Plugin::Driver
  # Is abstract by default
end

class MyManager::AnotherBaseDriver < MyManager::BaseDriver
  abstract_driver
end

class MyManager::MyUnsuitableDriver < MyManager::BaseDriver
  # +suitability+ method deliberately not implemented to test errors

  depends_on \
    :files => ["non_existent_file"],
    :directories => ["non_existent_directory"],
    :programs => ["non_existent_program"]

  def unavailable_method
    _raise_unless_available
  end
end

class MyManager::MyUnimplementedDriver < MyManager::BaseDriver
  def available?
    true
  end

  def suitability(method, *args)
    return 50
  end

  # +mymethod+ method deliberately not implemented to test errors
end


class MyManager::MyFirstDriver < MyManager::BaseDriver
  depends_on :directories => ["/"]

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

class MyManager::MySecondDriver < MyManager::BaseDriver
  def available?
    true
  end

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
  abstract_manager
end

class MyManagerSubclassImplementation < MyManagerSubclass
end
# }}}
#===[ rspec ]===========================================================

describe "AutomateIt::Plugin::Manager" do
  before(:all) do
    @x = AutomateIt::Plugin::Manager
  end

  it "should have plugins" do
    @x.classes.should include(MyManager)
  end

  it "should not have abstract plugins" do
    @x.classes.should_not include(MyManagerSubclass)
  end

  it "should have implementations of abstract plugins" do
    @x.classes.should include(MyManagerSubclassImplementation)
  end
end

describe "MyManager" do
  before(:all) do
    @m = MyManager.new
  end

  it "should have drivers" do
    for driver in [MyManager::MyUnsuitableDriver, MyManager::MyFirstDriver, MyManager::MySecondDriver]
      @m.class.driver_classes.should include(driver)
    end
  end

  it "should inherit common instance mehtods" do
    @m.should respond_to(:log)
  end

  it "should access drivers by index keys" do
    @m[:my_first_driver].should be_a_kind_of(MyManager::MyFirstDriver)
    @m.drivers[:my_first_driver].should be_a_kind_of(MyManager::MyFirstDriver)
  end

  it "should have aliased methods" do
    @m.class.aliased_methods.should include(:mymethod)
  end

  it "should respond to aliased methods" do
    @m.should respond_to(:mymethod)
  end

  it "should have an interpreter instance" do
    @m.interpreter.should be_a_kind_of(AutomateIt::Interpreter)
  end

  # XXX Plugins spec -- Instantiating a Plugin outside of an Interpreter should retain consistent object references
#  it "should inject interpreter instance into drivers" do
#    @m.interpreter.object_id.should == m[:my_first_driver].interpreter.object_id
#  end
end

describe "MyManager's drivers" do
  before(:all) do
    @m = MyManager.new
  end

  it "should be available" do
    MyManager::MyFirstDriver.new.available?.should be_true
  end

  it "should fail on unavailable methods" do
    lambda{ MyManager::MyUnsuitableDriver.new.unavailable_method }.should
      raise_error(NotImplementedError, /non_existent/)
  end

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
    rs = @m.driver_suitability_levels_for(:mymethod, :one => 1)
    rs[:my_first_driver].should == 10
    rs[:my_second_driver].should == 5
    rs[:my_unsuitable_driver].should be_nil
  end

  it "should choose suitable driver" do
    @m.driver_for(:mymethod, :one => 1).should be_a_kind_of(MyManager::MyFirstDriver)
  end

  it "should not choose driver if none match" do
    lambda { @m.driver_for(:mymethod, :one => 9) }.should raise_error(NotImplementedError)
  end

  it "should dispatch_to suitable driver" do
    @m.dispatch_to(:mymethod, :one => 1).should == 1
    @m.mymethod(:one => 1).should == 1
  end

  it "should fail dispatch_to if no suitable driver is found" do
    lambda { @m.dispatch_to(:mymethod, :one => 9) }.should raise_error(NotImplementedError)
    lambda { @m.mymethod(:one => 9) }.should raise_error(NotImplementedError)
  end

  it "should dispatch_to to default driver regardless of suitability" do
    @m.default(:my_unimplemented_driver)
    lambda { @m.dispatch_to(:mymethod, :one => 1) }.should raise_error(NoMethodError)
    lambda { @m.mymethod(:one => 1) }.should raise_error(NoMethodError)
  end

  it "should have an interpreter instance" do
    MyManager::MyFirstDriver.new.interpreter.should be_a_kind_of(AutomateIt::Interpreter)
  end

  it "should share object instances" do
    @m[:my_first_driver].should == @m.interpreter.my_manager[:my_first_driver]
  end
end

describe AutomateIt::Interpreter do
  before(:all) do
    @a = AutomateIt::Interpreter.new
  end

  it "should instantiate plugins" do
    @a.should respond_to(:plugins)
    @a.plugins.should include(:my_manager)
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
    @a.my_manager.interpreter.should == @a
  end

  it "should inject itself into drivers" do
    @a.my_manager[:my_first_driver].interpreter.should == @a
  end

  it "should not see abstract managers" do
    @a.plugins.should_not include(MyManagerSubclass.token)
  end

  it "should not see abstract drivers" do
    @a.my_manager.drivers.should_not include(MyManager::AnotherBaseDriver.token)
  end

  it "should not see base drivers" do
    @a.my_manager.drivers.should_not include(MyManager::BaseDriver.token)
  end
end
