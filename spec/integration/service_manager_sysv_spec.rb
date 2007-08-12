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
      @a = AutomateIt.new
      @m = @a.service_manager

      FileUtils.cp(SOURCE_FILE, SERVICE_FILE)
      FileUtils.chmod(0755, SERVICE_FILE)

    end

    before(:each) do
      @m.stop(SERVICE_NAME, :quiet => true) if @m.running?(SERVICE_NAME)
      @m.disable(SERVICE_NAME, :quiet => true) if @has_enable and @m.enabled?(SERVICE_NAME)
    end

    after(:all) do
      @m.stop(SERVICE_NAME, :quiet => true) if @m.running?(SERVICE_NAME)
      @m.disable(SERVICE_NAME, :quiet => true) if @has_enable and @m.enabled?(SERVICE_NAME)
      FileUtils.rm(SERVICE_FILE) if File.exists?(SERVICE_FILE)
    end

#    it "should be able to start, stop and check the running status of services" do
#      @m.running?(SERVICE_NAME).should be_false
#      @m.start(SERVICE_NAME, :quiet => true).should be_true
#      @m.start(SERVICE_NAME).should be_false
#      @m.running?(SERVICE_NAME).should be_true
#      @m.stop(SERVICE_NAME, :quiet => true).should be_true
#      @m.stop(SERVICE_NAME).should be_false
#      @m.running?(SERVICE_NAME).should be_false
#    end

    it "should be able to start a service" do
      @m.start(SERVICE_NAME, :quiet => true).should be_true
    end

    it "should not start an already running service" do
      @m.start(SERVICE_NAME, :quiet => true).should be_true
      @m.start(SERVICE_NAME).should be_false
    end

    it "should be able to stop a service" do
      @m.start(SERVICE_NAME, :quiet => true).should be_true
      @m.stop(SERVICE_NAME, :quiet => true).should be_true
    end

    it "should not stop a service that's not running" do
      @m.stop(SERVICE_NAME).should be_false
    end

    it "should be able to identify a non-running service" do
      @m.running?(SERVICE_NAME).should be_false
    end

    it "should be able to identify a running service" do
      @m.start(SERVICE_NAME, :quiet => true).should be_true
      @m.running?(SERVICE_NAME).should be_true
    end

    next unless @has_enable
    # TODO implement distro-specific variants
    #it "should be able to enable, disable and check the enabled status of services" do
    #  @m.enabled?(SERVICE_NAME).should be_false
    #  @m.enable(SERVICE_NAME, :quiet => true).should be_true
    #  @m.enabled?(SERVICE_NAME).should be_true
    #  @m.disable(SERVICE_NAME, :quiet => true).should be_true
    #  @m.enabled?(SERVICE_NAME).should be_false
    #end
  end
end
