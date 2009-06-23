require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

describe "AutomateIt::AddressManager::Portable" do
  before :all do
    @a = AutomateIt.new(:verbosity => Logger::WARN)
    @d = @a.address_manager[:portable]
  end

  it "should have hostnames" do
    @d.hostnames.should_not be_empty
  end

  it "should have localhost in hostnames" do
    @d.hostnames.should include("localhost")
    @d.has?("localhost").should be_true
  end

  it "should have machine's hostname in hostnames" do
    @d.hostnames.should include(Socket.gethostname)
    @d.has?(Socket.gethostname).should be_true
  end

  it "should have addresses" do
    @d.addresses.should_not be_empty
  end

  it "should have 127.0.0.1 in addresses" do
    @d.addresses.should include("127.0.0.1")
  end
end
