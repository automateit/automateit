require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

describe AutomateIt::Interpreter do
  before(:all) do
    @verbosity = Logger::WARN
    @a = AutomateIt::Interpreter.new(:verbosity => @verbosity)
  end

  it "should have a logger" do
    @a.log.should be_a_kind_of(Logger)
  end

  it "should be able to set a logger" do
    @old_logger = @a.log

    @a.log(QueuedLogger.new($stdout))
    @a.log.level = @verbosity

    @a.log.should_not == @old_logger
  end

  it "should provide a preview mode" do
    @a.preview = true
    @a.preview?.should be_true
    @a.preview_for("answer"){42}.should == :preview
    @a.noop?.should be_true
    @a.writing?.should be_false

    @a.preview = false
    @a.preview?.should be_false
    @a.preview_for("answer"){42}.should == 42
    @a.noop?.should be_false
    @a.writing?.should be_true

    @a.preview true
    @a.preview?.should be_true

    @a.noop false
    @a.preview?.should be_false

    @a.noop = true
    @a.preview?.should be_true

    @a.writing true
    @a.preview?.should be_false

    @a.writing = false
    @a.preview?.should be_true
  end

  it "should get and set values in the interpreter" do
    @a.set("meow", :MEOW).should == :MEOW
    @a.get("meow").should == :MEOW
    @a.meow.should == :MEOW
  end

  it "should eval commands within Interpreter's context" do
    @a.preview = true
    @a.instance_eval{preview?}.should be_true
    @a.instance_eval{self}.should == @a
    @a.instance_eval("preview?").should be_true
  end

  it "should be able to include methods into a class" do
    @a.preview = true
    @a.instance_eval do
      class MyInterpreterWrapper1
        def initialize(interpreter)
          interpreter.include_in(self)
        end

        def answer
          42
        end

        # Method overridden by Interpreter#preview?
        def preview?
          raise ArgumentError.new("MyInterpreterWrapper#preview? wasn't overriden")
        end
      end
      mc = MyInterpreterWrapper1.new(self)
      mc.answer.should == 42      # Instance method
      mc.preview?.should == true  # Interpreter method that overrides instance
      lambda{ mc.not_a_method }.should raise_error(NoMethodError)
    end
  end

  it "should be able to add method_missing to a class" do
    @a.preview = true
    @a.instance_eval do
      class MyInterpreterWrapper2
        def initialize(interpreter)
          interpreter.add_method_missing_to(self)
        end

        def answer
          42
        end

        # Method masking Interpreter#preview?
        def preview?
          42
        end
      end
      mc = MyInterpreterWrapper2.new(self)
      mc.answer.should == 42      # Instance method
      mc.preview?.should == 42       # Instance method masking Interpreter
      lambda{ mc.not_a_method }.should raise_error(NoMethodError)
    end
  end

  it "should be able to add method_missing to a class with an existing method_missing" do
    @a.preview = true
    @a.instance_eval do
      class MyInterpreterWrapper3
        def initialize(interpreter)
          interpreter.add_method_missing_to(self)
        end

        def method_missing(method, *args, &block)
          42
        end
      end
      mc = MyInterpreterWrapper3.new(self)
      mc.answer.should == 42      # Instance#method_missing
      mc.preview?.should == true  # Interpreter method
    end
  end
end
