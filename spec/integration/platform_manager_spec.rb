require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

# TODO Split PlatformManager into uname and an lsb subclass, this way I can have one set of tests check that "os" works on most platforms, while a more specific test checks for "distro". Also, I should catch errors in the Tags code so that only tags we know about will be injected, e.g. if "distro" isn't known, it shouldn't be added to tags -- currently it'll cause the tags setup process to fail with an IndexError.

begin
  raise IndexError unless String === INTERPRETER.platform_manager.query("os")

  describe "AutomateIt::PlatformManager" do
    before(:all) do
      @a = AutomateIt.new
      @m = @a.platform_manager
    end

    it "should query os" do
      String.should === @m.query("os")
    end

    it "should query arch" do
      String.should === @m.query(:arch)
    end

    it "should query os and arch" do
      String.should === @m.query("os#arch")
    end

    begin
      raise IndexError unless String === INTERPRETER.platform_manager.query("distro")

      it "should query distro" do
        String.should === @m.query("distro")
      end

      it "should query release" do
        String.should === @m.query(:release)
      end

      it "should fail on invalid LSB output" do
        if AutomateIt::PlatformManager::LSB === @m.driver_for(:query, :release)
          # XXX mocking a shared variable breaks it because the mock doesn't go away
          m = AutomateIt.new.platform_manager
          m[:lsb].send(:instance_eval, "@struct.delete(:release)")
          m[:lsb].class.send(:class_eval, "@@struct_cache.delete(:release)")
          m[:lsb].should_receive(:_read_lsb_release_output).and_return("not : valid : yaml")
          lambda{ m[:lsb].setup; m[:lsb].query(:release) }.should raise_error(ArgumentError, /invalid YAML/)
        end
      end

      it "should query combination of os, arch, distro and release" do
        result = @m.query("os#arch#distro#release")
        String.should === result
        elements = result.split(/_/)
        elements.size.should >= 4
        for element in elements
          String.should === element
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
