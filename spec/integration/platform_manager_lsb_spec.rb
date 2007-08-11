require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

VERSION_FILE="/proc/version"
interpreter = AutomateIt.new

unless interpreter.which("uname") and File.exists?(VERSION_FILE) and File.read(VERSION_FILE).match(/linux/i)
  puts "NOTE: This platform can't check #{__FILE__}"
else
  describe "AutomateIt::PlatformManager::LSB" do
    before do
      @m = AutomateIt::PlatformManager.new
    end

    it "should be linux" do
      `uname -s`.chomp.downcase.should == "linux"
      @m.query(:os).should == "linux"
    end

    it "should have values for query" do
      rs = @m.query("os#arch#distro#version")
      elements = rs.split(/_/)
      elements.size.should == 4
      for element in elements
        element.size.should > 0
        element.is_a?(String)
      end
  end

  end
end
