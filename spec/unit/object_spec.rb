require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

describe Object, "with extensions" do
  it "should have unique methods on an object" do
    INTERPRETER.unique_methods.should include(:preview)
  end

  it "should have unique methods on a class" do
    AutomateIt::Interpreter.unique_methods.should include(:invoke)
  end

  it "should parse arguments and options" do
    args, opts = args_and_opts(:foo, :bar, :baz => :quux)

    args.should == [:foo, :bar]
    opts.should == {:baz => :quux}
  end
end
