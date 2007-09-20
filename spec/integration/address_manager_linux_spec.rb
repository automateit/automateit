require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

if not INTERPRETER.euid?
  puts "NOTE: Can't check 'euid' on this platform, #{__FILE__}"
elsif not INTERPRETER.superuser?
  puts "NOTE: Must be root to check #{__FILE__}"
elsif not INTERPRETER.address_manager[:linux].available?
  puts "NOTE: Can't check AddressManager::Linux on this platform, #{__FILE__}"
else
  describe "AutomateIt::AddressManager::Linux" do
    before(:all) do
      @a = AutomateIt.new(:verbosity => Logger::WARN)
      @m = @a.address_manager

      @properties = {
        :device => "eth0",
        :label => "xxxx",
        :address => "10.0.0.249",
        :mask => "24",
        :announcements => 1,
      }

      @device_and_label = @properties[:device]+":"+@properties[:label]

      if @m.interfaces.include?(@device_and_label) \
          or @m.addresses.include?(@properties[:address])
        raise "ERROR: This computer already has the device/address used for testing! Either disable #{@device_and_label} and #{@properties[:address]}, or change the spec to test using different properties."
      end
    end

    after(:all) do
      @m.remove(@properties)
    end

    it "should find interfaces for top-level device" do
      @m.interfaces.should include(@properties[:device])
    end

    it "should not find non-existent device-label" do
      @m.interfaces.should_not include(@device_and_label)
    end

    it "should not find non-existant IP address" do
      @m.addresses.should_not include(@properties[:address])
    end

    it "should not have non-existent address bundles" do
      @m.has?(@properties).should be_false
    end

    it "should add an address" do
      @m.add(@properties).should be_true
      # Leaves active interface behind for other tests
    end

    it "should find added interface" do
      # Depends on active interface being created by earlier test
      @m.interfaces.should include(@device_and_label)
    end

    it "should find added IP address" do
      # Depends on active interface being created by earlier test
      @m.addresses.should include(@properties[:address])
    end

    it "should find added address using a properties bundle" do
      # Depends on user to be created by previous tests
      @m.has?(@properties).should be_true
    end

    it "should find added address using the IP address" do
      # Depends on user to be created by previous tests
      @m.has?(:address => @properties[:address]).should be_true
    end

    it "should find added address using device and label" do
      # Depends on user to be created by previous tests
      @m.has?(:device => @properties[:device], :label => @properties[:label]).should be_true
    end

    it "should remove an address" do
      # Depends on active interface being created by earlier test
      @m.remove(@properties).should be_true
    end

    it "should not have an interface after removing it" do
      @m.interfaces.should_not include(@device_and_label)
    end

    it "should not have an address after removing it" do
      @m.addresses.should_not include(@properties[:address])
    end

    it "should not have an address match a properties bundle after removing it" do
      @m.has?(@properties).should be_false
    end

    it "should not remove a non-existant address" do
      @m.remove(@properties).should be_false
    end

    it "should not re-add an existing address" do
      @m.add(@properties).should be_true
      @m.add(@properties).should be_false

      # Cleanup
      @m.remove(@properties).should be_true
    end

    it "should have hostnames" do
      @m.addresses.size.should >= 1
    end

    it "should be able to infer hostname variants" do
      @m.hostnames_for("kagami.lucky-channel").should == ["kagami", "kagami.lucky-channel"]
      @m.hostnames_for("kagami").should == ["kagami"]
    end
  end
end
