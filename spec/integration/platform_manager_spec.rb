require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

# TODO PlatformManager spec -- split entire spec into multiple, driver-specific ones.

begin
  raise IndexError unless String === INTERPRETER.platform_manager.query("os")

  describe "AutomateIt::PlatformManager" do
    before(:all) do
      @a = AutomateIt.new
      @m = @a.platform_manager
    end

    it "should query os" do
      @m.query("os").should be_a_kind_of(String)
    end

    it "should query arch" do
      @m.query(:arch).should be_a_kind_of(String)
    end

    it "should query os and arch" do
      @m.query("os#arch").should be_a_kind_of(String)
    end

    begin
      raise IndexError unless String === INTERPRETER.platform_manager.query("distro")

      it "should query distro" do
        @m.query("distro").should be_a_kind_of(String)
      end

      it "should query release" do
        @m.query(:release).should be_a_kind_of(String)
      end

      it "should query combination of os, arch, distro and release" do
        result = @m.query("os#arch#distro#release")
        result.should be_a_kind_of(String)
        elements = result.split(/_/)
        elements.size.should >= 4
        for element in elements
          element.should be_a_kind_of(String)
          element.size.should > 0
        end
      end
    rescue NotImplementedError, IndexError
      puts "NOTE: Can't check 'distro' query on this platform, #{__FILE__}"
    end
  end
rescue NotImplementedError, IndexError
  puts "NOTE: Can't check 'query' on this platform, #{__FILE__}"
end
