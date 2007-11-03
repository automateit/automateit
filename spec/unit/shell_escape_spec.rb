require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

describe String, "with shell escape" do
  it "should add quotes to string" do
    "foo".shell_escape.should == '"foo"'
  end

  it "should escape quotes within string" do
    '"foo"'.shell_escape.should == '"\"foo\""'
  end
end
