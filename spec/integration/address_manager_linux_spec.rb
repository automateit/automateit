require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

interpreter = AutomateIt.new

ADDRESS_PROPERTIES = {
  :device => "eth0",
  :label => "xxxx",
  :address => "10.0.0.249",
  :netmask => "24"
}

if not Process.euid.zero?
  puts "NOTE: Must be root to check #{__FILE__}"
elsif not interpreter.address_manager[:linux].suitability(:add, ADDRESS_PROPERTIES)
  puts "NOTE: This platform can't check #{__FILE__}"
else
  describe "AutomateIt::AddressManager::Linux" do
    before do
      @a = AutomateIt.new(:logger_level => Logger::WARN)
      @m = @a.address_manager
      if @m.has?(ADDRESS_PROPERTIES)
        @m.remove(ADDRESS_PROPERTIES)
      end
    end

    it "should be able to add, remove and check ownership of addresses" do
      @m.has?(ADDRESS_PROPERTIES).should be_false
      @m.add(ADDRESS_PROPERTIES).should be_true
      @m.has?(ADDRESS_PROPERTIES).should be_true
      @m.has?(:address => ADDRESS_PROPERTIES[:address]).should be_true
      @m.has?(:device => ADDRESS_PROPERTIES[:device], :label => ADDRESS_PROPERTIES[:label]).should be_true
      @m.remove(ADDRESS_PROPERTIES).should be_true
      @m.has?(ADDRESS_PROPERTIES).should be_false
    end
  end
end
