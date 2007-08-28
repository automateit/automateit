require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

describe "AutomateIt::AddressManager::Portable" do
  before :all do
    @a = AutomateIt.new(:verbosity => Logger::WARN)
    @d = @a.address_manager[:portable]
  end

  it "should have hostnames" do
    @d.hostnames.empty?.should be_false
  end

  it "should have localhost in hostnames" do
    @d.hostnames.include?("localhost").should be_true
    @d.has?("localhost").should be_true
  end

  it "should have machine's hostname in hostnames" do
    @d.hostnames.include?(Socket.gethostname).should be_true
    @d.has?(Socket.gethostname).should be_true
  end

  it "should have addresses" do
    @d.addresses.empty?.should be_false
  end

  it "should have 127.0.0.1 in addresses" do
    @d.addresses.include?("127.0.0.1").should be_true
  end
end
