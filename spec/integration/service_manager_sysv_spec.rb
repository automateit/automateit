require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

if not INTERPRETER.euid?
  puts "NOTE: Can't check 'euid' on this platform, #{__FILE__}"
elsif not INTERPRETER.superuser?
  puts "NOTE: Must be root to check #{__FILE__}"
elsif not INTERPRETER.service_manager[:sysv].available?
  puts "NOTE: Can't check ServiceManager::SYSV on this platform, #{__FILE__}"
else
  #---[ Shared ]----------------------------------------------------------
  describe AutomateIt::ServiceManager::SYSV, :shared => true do
    before(:all) do
      @a = AutomateIt.new(:verbosity => Logger::WARN)

      @service_name = "automateit_service_sysv_test"
      @service_file = "/etc/init.d/"+@service_name
      @source_file = File.join(File.dirname(__FILE__), "..", "extras", @service_name)
    end

    before(:each) do
      FileUtils.cp(@source_file, @service_file)
      FileUtils.chmod(0755, @service_file)

      INTERPRETER.service_manager.stop(@service_name, :quiet => true)

      @m = @a.service_manager
    end

    after(:all) do
      INTERPRETER.service_manager.stop(@service_name, :quiet => true)

      FileUtils.rm(@service_file) if File.exists?(@service_file)
    end
  end

  #---[ Start ]-----------------------------------------------------------
  describe AutomateIt::ServiceManager::SYSV, " with start" do
    it_should_behave_like "AutomateIt::ServiceManager::SYSV"

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

  end

  #---[ Wait ]------------------------------------------------------------
  describe AutomateIt::ServiceManager::SYSV, " when waiting", :shared => true do
    it_should_behave_like "AutomateIt::ServiceManager::SYSV"

    before(:all) do
      @timeout = 1
      @wait = @timeout+5
    end

    before(:each) do
      # Mocks need concrete object, rather than dispatcher
      @m = @a.service_manager[:sysv]
    end
  end

  describe AutomateIt::ServiceManager::SYSV, " when waiting with mock" do
    it_should_behave_like "AutomateIt::ServiceManager::SYSV when waiting"

    it "should wait for service to checking started status" do
      @m.should_receive(:tell).exactly(3).times.and_return(false, false, true)

      @m.started?(@service_name).should be_false
      @m.started?(@service_name, :wait => @wait).should be_true
    end

    it "should wait for service to checking stopped status" do
      @m.should_receive(:tell).exactly(3).times.and_return(true, true, false)

      @m.stopped?(@service_name).should be_false
      @m.stopped?(@service_name, :wait => @wait).should be_true
    end

    it "should pause for service to restart" do
      @m.should_receive(:tell).exactly(3).times.
        with(@service_name, :status, anything).and_return(false, false, true)
      @m.should_receive(:tell).once.
        with(@service_name, :stop, anything).and_return(true)
      @m.should_receive(:tell).once.
        with(@service_name, :start, anything).and_return(true)

      @m.restart(@service_name, :pause => @wait).should be_true
    end
  end

  if false
    # TODO: How to test waiting for real without long waits and race conditions? The example below does the same thing as the mocked version above, except by actually manipulating a service. The trouble with the real version is that there's a race condition between processes, which may cause the test to fail. For example, the #started? call might get the wrong value if the 'timeout' is too short or the 'wait' is too long. Increasing these reduces the likelihood that heavy system load will cause an error, but the test will take a very long time to run because of the sleep periods.

    describe AutomateIt::ServiceManager::SYSV, " when waiting with service" do
      it_should_behave_like "AutomateIt::ServiceManager::SYSV when waiting"

      it "should wait for service to restart" do
        @a.edit(@service_file, :backup => false, :params => {:timeout => @timeout}) do
          replace "touch $STATE", "sleep #{params[:timeout]} && touch $STATE &"
        end

        @m.start(@service_name, :quiet => true).should be_true
        @m.started?(@service_name).should be_false # Still starting
        @m.started?(@service_name, :wait => @wait).should be_true
        @m.restart(@service_name, :quiet => true, :wait => @wait).should be_true
        @m.started?(@service_name).should be_false # Still stopping
        @m.started?(@service_name, :wait => @wait).should be_true
      end
    end
  end

  #---[ Enable ]----------------------------------------------------------
  if INTERPRETER.service_manager.available?(:enabled?)
    describe AutomateIt::ServiceManager::SYSV, " with enable" do
      it_should_behave_like "AutomateIt::ServiceManager::SYSV"

      # Make tests independent? True is correct and lets you run individual
      # tests. False is faster but requires you to run the full suite.
      @independent = true

      before(:each) do
        @m.disable(@service_name, :quiet => true) unless @independent
      end

      after(:all) do
        @m.disable(@service_name, :quiet => true) unless @independent
      end

      it "should enable a service" do
        @m.enable(@service_name, :quiet => true).should be_true

        # Tear down
        @m.disable(@service_name, :quiet => true).should be_true if @independent
      end

      it "should not enable an enabled service" do
        @m.enable(@service_name, :quiet => true).should be_true
        @m.enable(@service_name, :quiet => true).should be_false

        # Tear down
        @m.disable(@service_name, :quiet => true).should be_true if @independent
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
        @m.disable(@service_name, :quiet => true).should be_true if @independent
      end
    end
  else
    puts "NOTE: Can't check 'enabled?' on this platform, #{__FILE__}"
  end
end
