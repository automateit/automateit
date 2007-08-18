require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

ADDRESS_PROPERTIES = {
  :device => "eth0",
  :label => "xxxx",
  :address => "10.0.0.249",
  :mask => "24",
  :announcements => 1,
}

interpreter = AutomateIt.new

if not interpreter.superuser?
  puts "NOTE: Must be root to check #{__FILE__}"
elsif not interpreter.address_manager[:linux].suitability(:add, ADDRESS_PROPERTIES)
  puts "NOTE: This platform can't check #{__FILE__}"
else
  describe "AutomateIt::AddressManager::Linux" do
    before(:all) do
      @a = AutomateIt.new(:verbosity => Logger::WARN)
      @m = @a.address_manager
      @device_and_label = ADDRESS_PROPERTIES[:device]+":"+ADDRESS_PROPERTIES[:label]

      if @m.interfaces.include?(@device_and_label) \
          or @m.addresses.include?(ADDRESS_PROPERTIES[:address])
        raise "ERROR: This computer already has the device/address used for testing! Either disable #{@device_and_label} and #{ADDRESS_PROPERTIES[:address]}, or change the spec to test using different properties."
      end
    end

    before(:each) do
      @m.remove(ADDRESS_PROPERTIES)
    end

    after do
      @m.remove(ADDRESS_PROPERTIES)
    end

    # TODO Split this block up into multiple, inter-dependant specs?
    it "should be able to add and remove addresses, check their ownership and presence" do
      @m.interfaces.include?(ADDRESS_PROPERTIES[:device]).should be_true
      @m.interfaces.include?(@device_and_label).should be_false
      @m.addresses.include?(ADDRESS_PROPERTIES[:address]).should be_false
      @m.has?(ADDRESS_PROPERTIES).should be_false

      @m.add(ADDRESS_PROPERTIES).should be_true
      @m.interfaces.include?(@device_and_label).should be_true
      @m.addresses.include?(ADDRESS_PROPERTIES[:address]).should be_true
      @m.has?(ADDRESS_PROPERTIES).should be_true
      @m.has?(:address => ADDRESS_PROPERTIES[:address]).should be_true
      @m.has?(:device => ADDRESS_PROPERTIES[:device], :label => ADDRESS_PROPERTIES[:label]).should be_true

      @m.remove(ADDRESS_PROPERTIES).should be_true
      @m.interfaces.include?(@device_and_label).should be_false
      @m.addresses.include?(ADDRESS_PROPERTIES[:address]).should be_false
      @m.has?(ADDRESS_PROPERTIES).should be_false
    end

    it "should not remove a non-existant address" do
      @m.remove(ADDRESS_PROPERTIES).should be_false
    end

    it "should not re-add an existing address" do
      @m.add(ADDRESS_PROPERTIES).should be_true
      @m.add(ADDRESS_PROPERTIES).should be_false
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
