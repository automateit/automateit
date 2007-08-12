require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")


begin
  raise IndexError unless AutomateIt.new.platform_manager.query("os").is_a?(String)

  describe "AutomateIt::PlatformManager" do
    before(:all) do
      @a = AutomateIt.new
      @m = @a.platform_manager
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
rescue NotImplementedError, IndexError
  puts "NOTE: This platform can't check #{__FILE__}"
end
