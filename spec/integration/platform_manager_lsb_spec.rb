require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

# TODO Use tags to limit execution to suitable hosts. To test the class, it has to respond correctly to tags, which is misleading, but that's why this is an integration test. Besides, if that's failing, then running the specific test will complain and thus indicate that something is wrong, so that's okay.

Ai = AutomateIt.new
Uname = Ai.which("uname")

unless Uname
  puts "WARNING: This platform can't test #{__FILE__}"
else
  describe "AutomateIt::PlatformManager::LSB" do
    before do
      @m = AutomateIt::PlatformManager.new
    end

    # TODO what if a non-Linux supports LSB!?
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
