require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

describe AutomateIt::Interpreter do
  before do
    @a = AutomateIt::Interpreter.new
  end

  it "should have a logger" do
    @a.log.is_a?(Logger)
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
    @a.eval{noop?}.should be_true
    @a.eval{self}.should == @a
  end
end
