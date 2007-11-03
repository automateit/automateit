require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

describe AutomateIt::AddressManager do
  before(:all) do
    @a = AutomateIt.new(:verbosity => Logger::WARN)
    @m = @a.address_manager
    @d = @a.address_manager.driver_for(:hostnames_for)
  end

  it "should be able to convert netmasks to CIDR addresses" do
    @d.send(:mask_to_cidr, "255.255.255.0").should == 24
  end

  it "should be able to convert CIDR addresses to netmasks" do
    @d.send(:cidr_to_mask, 24).should == "255.255.255.0"
  end

  it "should be able to convert decimals to binaries" do
    @d.send(:dec2bin, 255).should == "11111111"
  end

  it "should be able to convert binaries to decimals" do
    @d.send(:bin2dec, "11111111").should == 255
  end

  it "should be able to derive interface and label from a device" do
    @d.send(:_interface_and_label, :device => "eth0").should == "eth0"
  end

  it "should be able to derive interface and label from a device and alias" do
    @d.send(:_interface_and_label, :device => "eth0", :label => "1").should == "eth0:1"
  end

  it "should fail to derive interface and lable from inadequate options" do
    lambda { @d.send(:_interface_and_label, :label => "1") }.should raise_error(ArgumentError)
  end

  it "should be able to prepend arguments to ifconfig commands" do
    @d.send(:_ifconfig_helper, :del, 
      {:address => "127.0.0.1", :device => "eth0", :label => "1"}, 
      {:prepend => "inet"}).should == "ifconfig eth0:1 inet 127.0.0.1 down"
  end

  it "should be able to append arguments to ifconfig commands" do
    @d.send(:_ifconfig_helper, :del, 
      {:address => "127.0.0.1", :device => "eth0", :label => "1"}, 
      {:append => "unplumb"}).should == "ifconfig eth0:1 127.0.0.1 down unplumb"
  end
end
