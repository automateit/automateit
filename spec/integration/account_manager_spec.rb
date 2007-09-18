require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

if not INTERPRETER.euid?
  puts "NOTE: Can't check 'euid' on this platform, #{__FILE__}"
elsif not INTERPRETER.superuser?
  puts "NOTE: Must be root to check #{__FILE__}"
elsif not INTERPRETER.account_manager.available?(:add_user)
  puts "NOTE: Can't find AccountManager for this platform, #{__FILE__}"
else
  describe "AutomateIt::AccountManager" do
    before(:all) do
      @a = AutomateIt.new(:verbosity => Logger::WARN)
      @m = @a.account_manager

      @username = "automateit_testuser"
      @groupname = "automateit_testgroup"

      raise "User named '#{@username}' found. If this isn't a real user, delete it so that the test can contineu. If this is a real user, change the spec to test with a user that shouldn't exist." if @m.users[@username]
      raise "Group named '#{@groupname}' found. If this isn't a real group, delete it so that the test can contineu. If this is a real group, change the spec to test with a group that shouldn't exist." if @m.groups[@groupname]
    end

    after(:all) do
      @m.remove_user(@username, :quiet => true)
      @m.remove_group(@username, :quiet => true)
      @m.remove_group(@groupname, :quiet => true)
    end

    it "should find root user" do
      entry = @m.users["root"]
      entry.should_not be_nil
      entry.uid.should == 0
    end

    it "should not have a user before one is created" do
      @m.has_user?(@username).should be_false
    end

    it "should create a user" do
      entry = @m.add_user(@username, :passwd => "asdf", :shell => "/bin/false")

      entry.should_not be_nil
      entry.name.should == @username
      # Leaves behind user for further tests
    end

    it "should have a user after one is created" do
      # Depends on user to be created by previous tests
      @m.has_user?(@username).should be_true
    end

    it "should query user data by name" do
      # Depends on user to be created by previous tests
      entry = @m.users[@username]
      entry.should_not be_nil
      entry.name.should == @username
    end

    it "should query user data by id" do
      # Depends on user to be created by previous tests
      uid = @m.users[@username].uid

      entry = @m.users[uid]
      entry.should_not be_nil
      entry.name.should == @username
    end

    it "should not query user data by invalid type" do
      lambda{ @m.users[false] }.should raise_error(TypeError)
    end

    it "should create user group" do
      # Depends on user to be created by previous tests
      @m.groups[@username].should_not be_nil
    end

    it "should not re-add an existing user" do
      # Depends on user to be created by previous tests
      @m.add_user(@username).should be_false
    end

    it "should not have a non-existent group" do
      @m.has_group?(@groupname).should be_false
    end

    it "should add a group" do
      entry = @m.add_group(@groupname)
      entry.should_not be_nil
      entry.name.should == @groupname
      # Leaves behind group for further tests
    end

    it "should not re-add a group" do
      @m.add_group(@groupname).should be_false
    end

    it "should query group data by name" do
      entry = @m.groups[@groupname]
      entry.should_not be_nil
      entry.name.should == @groupname
    end

    it "should query group data by id" do
      gid = @m.groups[@groupname].gid

      entry = @m.groups[gid]
      entry.should_not be_nil
      entry.name.should == @groupname
    end

    it "should not query group data by invalid type" do
      lambda{ @m.groups[false] }.should raise_error(TypeError)
    end

    it "should remove a group" do
      # Depends on group to be created by previous tests
      @m.remove_group(@groupname).should be_true
    end

    it "should not remove a non-existent group" do
      @m.remove_group(@groupname).should be_false
    end

    it "should not have members for a non-existent group" do
      @m.users_for_group(@groupname).should == []
    end

    it "should add a group with members" do
      # Depends on user to be created by previous tests
      @m.add_group(@groupname, :members => @username)
      # Leaves behind group for further tests
    end

    it "should query users in a group" do
      # Depends on group to be created by previous tests
      @m.users_for_group(@groupname).should == [@username]
    end

    it "should query groups for a user" do
      # Depends on user to be created by previous tests
      # Depends on group to be created by previous tests
      @m.groups_for_user(@username).should include(@groupname)
    end

    it "should remove users from a group" do
      # Depends on user to be created by previous tests
      # Depends on group to be created by previous tests
      @m.remove_users_from_group(@username, @groupname).should == [@username]
    end

    it "should add groups to a user" do
      # Depends on user to be created by previous tests
      @m.add_groups_to_user(@groupname, @username).should == [@groupname]
    end

    it "should remove groups from user" do
      # Depends on user to be created by previous tests
      @m.remove_groups_from_user(@groupname, @username).should == [@groupname]
    end

    it "should remove a group with members" do
      # Depends on group to be created by previous tests
      @m.remove_group(@groupname).should be_true
    end

    it "should not add users to non-existent group" do
      lambda{ @m.add_users_to_group(@username, @groupname) }.should raise_error(ArgumentError)
    end

    it "should pretend to add users to non-existent group in noop mode" do
      begin
        @a.noop true
        @m.add_users_to_group(@username, @groupname).should == [@username]
      ensure
        @a.noop false
      end
    end

    it "should not remove users from non-existent group" do
      lambda{ @m.remove_users_from_group(@username, @groupname) }.should raise_error(ArgumentError)
    end

    it "should pretend to remove users from non-existent group in noop mode" do
      begin
        @a.noop true
        @m.remove_users_from_group(@username, @groupname).should == [@username]
      ensure
        @a.noop false
      end
    end

    it "should change password" do
      # Depends on user to be created by previous tests
      pass = "automateit"

      # TODO This isn't portable
      def extract_pwent(username)
        for filename in %w(/etc/shadow /etc/passwd)
          next unless File.exist?(filename)
          return File.read(filename).split(/\n/).grep(/^#{username}\b/)
        end
      end

      before = extract_pwent(@username)
      @m.passwd(@username, pass).should be_true
      after = extract_pwent(@username)
      before.should_not eql(after)
    end

    it "should remove a user" do
      # Depends on user to be created by previous tests
      @m.remove_user(@username, :quiet => true).should be_true
    end

    it "should not remove a non-existent user" do
      @m.remove_user(@username).should be_false
    end
  end
end
