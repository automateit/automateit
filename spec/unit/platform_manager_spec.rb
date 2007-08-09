require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

describe "AutomateIt::PlatformManager" do
  before do
    @m = AutomateIt::PlatformManager.new(:default => :struct, :struct => {
      :os => "mizrahi", 
      :arch => "realian",
      :distro => "momo",
      :version => "s100",
    })
  end

  it "should query key by symbol" do
    @m.query(:os).should == "mizrahi"
  end

  it "should query key by string" do
    @m.query("distro").should == "momo"
  end

  it "should query by two-key query" do
    @m.query("os#arch").should == "mizrahi_realian"
    @m.query("distro#version").should == "momo_s100"
  end

  it "should query by three-part query" do
    @m.query("os#distro#version").should == "mizrahi_momo_s100"
    @m.query("distro#version#arch").should == "momo_s100_realian"
  end

  it "should query by aliases" do
    @m.query("release#version").should == "s100_s100"
  end

  it "should fail on invalid top-level keys" do
    lambda { @m.query(:asdf) }.should raise_error(IndexError)
  end

  it "should fail on invalid subkeys" do
    lambda { @m.query("os#asdf") }.should raise_error(IndexError)
  end

end
