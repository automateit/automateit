require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

# TODO Split PlatformManager into uname and an lsb subclass, this way I can have one set of tests check that "os" works on most platforms, while a more specific test checks for "distro". Also, I should catch errors in the Tags code so that only tags we know about will be injected, e.g. if "distro" isn't known, it shouldn't be added to tags -- currently it'll cause the tags setup process to fail with an IndexError.

begin
  raise IndexError unless AutomateIt.new.platform_manager.query("os").is_a?(String)

  describe "AutomateIt::PlatformManager" do
    before(:all) do
      @a = AutomateIt.new
      @m = @a.platform_manager
    end

    it "should query os" do
      @m.query("os").is_a?(String).should be_true
    end

    it "should query arch" do
      @m.query(:arch).is_a?(String).should be_true
    end

    it "should query os and arch" do
      @m.query("os#arch").is_a?(String).should be_true
    end

    begin
      raise IndexError unless AutomateIt.new.platform_manager.query("distro").is_a?(String)

      it "should query distro" do
        @m.query("distro").is_a?(String).should be_true
      end

      it "should query release" do
        @m.query(:release).is_a?(String).should be_true
      end

      it "should query combination of os, arch, distro and release" do
        result = @m.query("os#arch#distro#release")
        result.is_a?(String).should be_true
        elements = result.split(/_/)
        elements.size.should >= 4
        for element in elements
          element.is_a?(String)
          element.size.should > 0
        end
      end
    rescue NotImplementedError, IndexError
      puts "NOTE: This platform lacks driver to query 'distro' in #{__FILE__}"
    end
  end
rescue NotImplementedError, IndexError
  puts "NOTE: This platform can't check #{__FILE__}"
end
