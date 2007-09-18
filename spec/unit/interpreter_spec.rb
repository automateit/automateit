require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

describe AutomateIt::Interpreter do
  before(:all) do
    @a = AutomateIt::Interpreter.new
  end

  it "should have a logger" do
    @a.log.should be_a_kind_of(Logger)
  end

  it "should have noop (dryrun) detection" do
    @a.noop = true
    @a.noop?.should be_true
    @a.noop?{9}.should == 9
    @a.writing?.should be_false
    @a.writing?{9}.should be_false

    @a.writing(true)
    @a.noop?.should be_false
    @a.noop?{9}.should be_false
    @a.writing?.should be_true
    @a.writing?{9}.should == 9
  end

  it "should eval commands in context" do
    @a.noop = true
    @a.instance_eval{noop?}.should be_true
    @a.instance_eval{self}.should == @a
    @a.instance_eval("noop?").should be_true
  end

  it "should be able to include methods into a class" do
    @a.noop true
    @a.instance_eval do
      class MyInterpreterWrapper1
        def initialize(interpreter)
          interpreter.include_in(self)
        end

        def answer
          42
        end

        # Method overridden by Interpreter#noop?
        def noop?
          raise ArgumentError.new("MyInterpreterWrapper#noop? wasn't overriden")
        end
      end
      mc = MyInterpreterWrapper1.new(self)
      mc.answer.should == 42      # Instance method
      mc.noop?.should == true     # Interpreter method that overrides instance
      mc.writing?.should == false # Interpreter method not included
      lambda{ mc.not_a_method }.should raise_error(NoMethodError)
    end
  end

  it "should be able to add method_missing to a class" do
    @a.noop true
    @a.instance_eval do
      class MyInterpreterWrapper2
        def initialize(interpreter)
          interpreter.add_method_missing_to(self)
        end

        def answer
          42
        end

        # Method masking Interpreter#noop?
        def noop?
          42
        end
      end
      mc = MyInterpreterWrapper2.new(self)
      mc.answer.should == 42      # Instance method
      mc.noop?.should == 42       # Instance method masking Interpreter
      mc.writing?.should == false # interpreter method
      lambda{ mc.not_a_method }.should raise_error(NoMethodError)
    end
  end

  it "should be able to add method_missing to a class with an existing method_missing" do
    @a.noop true
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
      mc.noop?.should == true     # Interpreter method
      mc.writing?.should == false # Interpreter method
    end
  end
end
