require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

if not INTERPRETER.euid?
  puts "NOTE: Can't check 'euid' on this platform, #{__FILE__}"
elsif not INTERPRETER.superuser?
  puts "NOTE: Must be root to check #{__FILE__}"
elsif not INTERPRETER.service_manager[:sysv].available?
  puts "NOTE: Can't check ServiceManager::SYSV on this platform, #{__FILE__}"
else
  describe "AutomateIt::ServiceManager::SYSV" do
    begin
      INTERPRETER.service_manager.driver_for(:enabled?, @service_name)
      @has_enable = true
    rescue NotImplementedError
      @has_enable = false
      puts "NOTE: Can't check 'enabled?' on this platform, #{__FILE__}"
    end

    before(:all) do
      @a = AutomateIt.new(:verbosity => Logger::WARN)
      @m = @a.service_manager

      @service_name = "automateit_service_sysv_test"
      @service_file = "/etc/init.d/"+@service_name
      @source_file = File.join(File.dirname(__FILE__), "..", "extras", @service_name)
    end

    before(:each) do
      FileUtils.cp(@source_file, @service_file)
      FileUtils.chmod(0755, @service_file)

      @m.stop(@service_name, :quiet => true) if @m.running?(@service_name)
    end

    after(:all) do
      @m.stop(@service_name, :quiet => true) if @m.running?(@service_name)
      FileUtils.rm(@service_file) if File.exists?(@service_file)
    end

    it "should start a service" do
      @m.start(@service_name, :quiet => true).should be_true
    end

    it "should not start an already running service" do
      @m.start(@service_name, :quiet => true).should be_true
      @m.start(@service_name).should be_false
    end

    it "should stop a service" do
      @m.start(@service_name, :quiet => true).should be_true
      @m.stop(@service_name, :quiet => true).should be_true
    end

    it "should not stop a service that's not running" do
      @m.stop(@service_name).should be_false
    end

    it "should identify a non-running service" do
      @m.running?(@service_name).should be_false
    end

    it "should identify a running service" do
      @m.start(@service_name, :quiet => true).should be_true
      @m.running?(@service_name).should be_true
    end

    it "should wait for service to restart" do
      # NOTE: Test depends on race condition because checks must pass before the service starts

      timeout = 1
      wait = timeout+2
      @a.edit(@service_file, :backup => false) do
        replace "touch $STATE", "sleep #{timeout} && touch $STATE &"
      end

      @m.start(@service_name, :quiet => true).should be_true
      @m.started?(@service_name).should be_false # Still starting
      @m.started?(@service_name, :wait => wait).should be_true
      @m.restart(@service_name, :quiet => true, :wait => wait).should be_true
      @m.started?(@service_name).should be_false
      @m.started?(@service_name, :wait => wait).should be_true
    end

    if @has_enable
      # It's more correct to disable the service using before/after, but the
      # platform-specific scripts are ridiculously slow, so manually disabling
      # the service only when necessary significantly speeds the test.
      @disable_manually = true

      before(:each) do
        @m.disable(@service_name, :quiet => true) if not @disable_manually
      end

      after(:all) do
        @m.disable(@service_name, :quiet => true) if not @disable_manually
      end

      it "should enable a service" do
        @m.enable(@service_name, :quiet => true).should be_true
        # Tear down
        @m.disable(@service_name, :quiet => true).should be_true if @disable_manually
      end

      it "should not enable an enabled service" do
        @m.enable(@service_name, :quiet => true).should be_true
        @m.enable(@service_name, :quiet => true).should be_false
        # Tear down
        @m.disable(@service_name, :quiet => true).should be_true if @disable_manually
      end

      it "should disable a service" do
        @m.enable(@service_name, :quiet => true).should be_true
        @m.disable(@service_name, :quiet => true).should be_true
      end

      it "should not disable a disabled service" do
        @m.disable(@service_name, :quiet => true).should be_false
      end

      it "should identify a disabled service" do
        @m.enabled?(@service_name).should be_false
      end

      it "should identify an enabled service" do
        @m.enable(@service_name, :quiet => true).should be_true
        @m.enabled?(@service_name).should be_true
        # Tear down
        @m.disable(@service_name, :quiet => true).should be_true if @disable_manually
      end
    end
  end
end
