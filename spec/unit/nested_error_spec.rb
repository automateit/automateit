require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

describe NestedError do
  it "should preserve the cause" do
    e = NestedError.new("nested message", TypeError.new("cause message"))
    e.message.should == "nested message"
    e.cause.class.should == TypeError
    e.cause.message.should == "cause message"
  end
end
