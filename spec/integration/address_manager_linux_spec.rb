require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

if not INTERPRETER.superuser?
  puts "NOTE: Must be root to check #{__FILE__}"
elsif not INTERPRETER.address_manager[:linux].available?
  puts "NOTE: This platform can't check #{__FILE__}"
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

    before(:each) do
      @m.remove(@properties)
    end

    after do
      @m.remove(@properties)
    end

    # TODO Split this block up into multiple, inter-dependant specs?
    it "should be able to add and remove addresses, check their ownership and presence" do
      @m.interfaces.include?(@properties[:device]).should be_true
      @m.interfaces.include?(@device_and_label).should be_false
      @m.addresses.include?(@properties[:address]).should be_false
      @m.has?(@properties).should be_false

      @m.add(@properties).should be_true
      @m.interfaces.include?(@device_and_label).should be_true
      @m.addresses.include?(@properties[:address]).should be_true
      @m.has?(@properties).should be_true
      @m.has?(:address => @properties[:address]).should be_true
      @m.has?(:device => @properties[:device], :label => @properties[:label]).should be_true

      @m.remove(@properties).should be_true
      @m.interfaces.include?(@device_and_label).should be_false
      @m.addresses.include?(@properties[:address]).should be_false
      @m.has?(@properties).should be_false
    end

    it "should not remove a non-existant address" do
      @m.remove(@properties).should be_false
    end

    it "should not re-add an existing address" do
      @m.add(@properties).should be_true
      @m.add(@properties).should be_false
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
