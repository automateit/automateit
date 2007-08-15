require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

SERVICE_NAME = "automateit_service_sysv_test"
SERVICE_FILE = "/etc/init.d/"+SERVICE_NAME
SOURCE_FILE = File.join(File.dirname(__FILE__), "..", "extras", SERVICE_NAME)

interpreter = AutomateIt.new

if not interpreter.superuser?
  puts "NOTE: Must be root to check in #{__FILE__}"
elsif not interpreter.service_manager[:sysv].suitability(:running?, SERVICE_NAME)
  puts "NOTE: This platform can't check #{__FILE__}"
else
  describe "AutomateIt::ServiceManager::SYSV" do
    begin
      AutomateIt.new.service_manager.driver_for(:enabled?, SERVICE_NAME)
      @has_enable = true
    rescue NotImplementedError
      @has_enable = false
      puts "NOTE: This platform lacks driver for +enabled?+ in #{__FILE__}"
    end

    before(:all) do
      @a = AutomateIt.new(:verbosity => Logger::WARN)
      @m = @a.service_manager

      FileUtils.cp(SOURCE_FILE, SERVICE_FILE)
      FileUtils.chmod(0755, SERVICE_FILE)
    end

    before(:each) do
      @m.stop(SERVICE_NAME, :quiet => true) if @m.running?(SERVICE_NAME)
    end

    after(:all) do
      @m.stop(SERVICE_NAME, :quiet => true) if @m.running?(SERVICE_NAME)
      FileUtils.rm(SERVICE_FILE) if File.exists?(SERVICE_FILE)
    end

    it "should start a service" do
      @m.start(SERVICE_NAME, :quiet => true).should be_true
    end

    it "should not start an already running service" do
      @m.start(SERVICE_NAME, :quiet => true).should be_true
      @m.start(SERVICE_NAME).should be_false
    end

    it "should stop a service" do
      @m.start(SERVICE_NAME, :quiet => true).should be_true
      @m.stop(SERVICE_NAME, :quiet => true).should be_true
    end

    it "should not stop a service that's not running" do
      @m.stop(SERVICE_NAME).should be_false
    end

    it "should identify a non-running service" do
      @m.running?(SERVICE_NAME).should be_false
    end

    it "should identify a running service" do
      @m.start(SERVICE_NAME, :quiet => true).should be_true
      @m.running?(SERVICE_NAME).should be_true
    end

    if @has_enable
      # It's more correct to disable the service using before/after, but the
      # platform-specific scripts are ridiculously slow, so manually disabling
      # the service only when necessary significantly speeds the test.
      @disable_manually = true

      before(:each) do
        @m.disable(SERVICE_NAME, :quiet => true) if not @disable_manually
      end

      after(:all) do
        @m.disable(SERVICE_NAME, :quiet => true) if not @disable_manually
      end

      it "should enable a service" do
        @m.enable(SERVICE_NAME, :quiet => true).should be_true
        # Tear down
        @m.disable(SERVICE_NAME, :quiet => true).should be_true if @disable_manually
      end

      it "should not enable an enabled service" do
        @m.enable(SERVICE_NAME, :quiet => true).should be_true
        @m.enable(SERVICE_NAME, :quiet => true).should be_false
        # Tear down
        @m.disable(SERVICE_NAME, :quiet => true).should be_true if @disable_manually
      end

      it "should disable a service" do
        @m.enable(SERVICE_NAME, :quiet => true).should be_true
        @m.disable(SERVICE_NAME, :quiet => true).should be_true
      end

      it "should not disable a disabled service" do
        @m.disable(SERVICE_NAME, :quiet => true).should be_false
      end

      it "should identify a disabled service" do
        @m.enabled?(SERVICE_NAME).should be_false
      end

      it "should identify an enabled service" do
        @m.enable(SERVICE_NAME, :quiet => true).should be_true
        @m.enabled?(SERVICE_NAME).should be_true
        # Tear down
        @m.disable(SERVICE_NAME, :quiet => true).should be_true if @disable_manually
      end
    end
  end
end
