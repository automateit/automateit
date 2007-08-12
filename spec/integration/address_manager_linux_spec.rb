require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

ADDRESS_PROPERTIES = {
  :device => "eth0",
  :label => "xxxx",
  :address => "10.0.0.249",
  :netmask => "24",
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
      @a = AutomateIt.new(
        :verbosity => Logger::WARN
      )
      @m = @a.address_manager
    end

    before(:each) do
      @m.remove(ADDRESS_PROPERTIES) if @m.has?(ADDRESS_PROPERTIES)
    end

    after do
      @m.remove(ADDRESS_PROPERTIES) if @m.has?(ADDRESS_PROPERTIES)
    end

    it "should be able to add and remove addresses, check their ownership and presence" do
      @m.interfaces.include?(ADDRESS_PROPERTIES[:device]).should be_true
      @m.interfaces.include?(ADDRESS_PROPERTIES[:device]+":"+ADDRESS_PROPERTIES[:label]).should be_false
      @m.addresses.include?(ADDRESS_PROPERTIES[:address]).should be_false
      @m.has?(ADDRESS_PROPERTIES).should be_false

      @m.add(ADDRESS_PROPERTIES).should be_true
      @m.interfaces.include?(ADDRESS_PROPERTIES[:device]+":"+ADDRESS_PROPERTIES[:label]).should be_true
      @m.addresses.include?(ADDRESS_PROPERTIES[:address]).should be_true
      @m.has?(ADDRESS_PROPERTIES).should be_true
      @m.has?(:address => ADDRESS_PROPERTIES[:address]).should be_true
      @m.has?(:device => ADDRESS_PROPERTIES[:device], :label => ADDRESS_PROPERTIES[:label]).should be_true

      @m.remove(ADDRESS_PROPERTIES).should be_true
      @m.interfaces.include?(ADDRESS_PROPERTIES[:device]+":"+ADDRESS_PROPERTIES[:label]).should be_false
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
  end
end
