require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

describe "HashCache" do
  before(:each) do
    @c = HashCache.new
  end

  it "should store and fetch values" do
    @c.store("foo", "bar")
    @c.fetch("foo").should == "bar"
  end

  it "should store values when needed if given a block" do
    @c.fetch("foo"){"bar"}.should == "bar"
    @c.fetch("foo").should == "bar"
  end

  it "should use HashCached values" do
    @c.fetch("foo"){"bar"}.should == "bar"
    @c.fetch("foo"){raise Exception.new("won't be raised")}.should == "bar"
  end

  it "should invalidate values" do
    @c.store("foo", "bar")
    @c.delete("foo")
    @c.fetch("foo").should be_nil
  end
end
