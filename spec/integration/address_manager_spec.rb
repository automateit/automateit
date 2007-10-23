require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

if not INTERPRETER.euid?
  puts "NOTE: Can't check 'euid' on this platform, #{__FILE__}"
elsif not INTERPRETER.superuser?
  puts "NOTE: Must be root to check #{__FILE__}"
else
  describe AutomateIt::AddressManager, :shared => true do
    before(:all) do
      # Should examples be independent? True is correct and lets you run a
      # single example. False is evil and requires you to run the entire suite,
      # but it's much faster. On Linux false yields a 5x speed-up.
      @independent = false

      @a = AutomateIt.new(:verbosity => Logger::WARN)
      @m = @a.address_manager
    end

    after(:all) do
      @m.remove(@properties)
    end

    after(:each) do
      @m.remove(@properties) if @independent
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
    end

    it "should find added interface" do
      @m.add(@properties).should be_true if @independent

      @m.interfaces.should include(@has_named_aliases ? @device_and_label : @device)
    end

    it "should find added IP address" do
      @m.add(@properties).should be_true if @independent

      @m.addresses.should include(@properties[:address])
    end

    it "should find added address using a properties bundle" do
      @m.add(@properties).should be_true if @independent

      @m.has?(@properties).should be_true
    end

    it "should find added address using the IP address" do
      @m.add(@properties).should be_true if @independent

      @m.has?(:address => @properties[:address]).should be_true
    end

    it "should find added address using device and label" do
      @m.add(@properties).should be_true if @independent

      @m.has?(:device => @properties[:device], :label => @properties[:label]).should be_true
    end

    it "should remove an address" do
      @m.add(@properties).should be_true if @independent

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

  #---[ Targets ]---------------------------------------------------------

  @checked_address_manager = false
  %w(linux sunos openbsd freebsd).each do |driver_name|
    driver_token = driver_name.to_sym
    driver = INTERPRETER.address_manager[driver_token]
    if driver.available?
      @checked_address_manager = true
      
      describe driver.class.to_s do
        it_should_behave_like "AutomateIt::AddressManager"

        before(:all) do
          @driver_token = driver_token

          @properties = {
            :device => @m.interfaces.reject{|t| t =~ /^lo\d+$/}.first,
            :label => "1",
            :address => "10.0.0.249",
            :mask => "24",
          }

          @has_named_aliases = true

          case driver_token
          when :sunos
            # Accept defaults
          when :openbsd, :freebsd
            @has_named_aliases = false
          when :linux
            @properties[:label] = "atst"
            @properties[:announcements] = 1
          else
            raise ArgumentError.new("Unknown defaults for AddressManager driver: #{driver_token}")
          end

          @device = @properties[:device]
          @device_and_label = @properties[:device]+":"+@properties[:label]

          if @m.interfaces.include?(@device_and_label) \
              or @m.addresses.include?(@properties[:address])
            raise "ERROR: This computer already has the device/address used for testing! Either disable #{@device_and_label} and #{@properties[:address]}, or change the spec to test using different properties."
          end

          @d = @m[driver_token]
        end
      end
    end
  end
  
  unless @checked_address_manager
    puts "Can't find AddressManager for this platform, #{__FILE__}"
  end
end
