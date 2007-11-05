require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

if not INTERPRETER.euid?
  puts "NOTE: Can't check 'euid' on this platform, #{__FILE__}"
elsif not INTERPRETER.superuser?
  puts "NOTE: Must be root to check #{__FILE__}"
elsif (INTERPRETER.account_manager.available?(:users) && INTERPRETER.account_manager.available?(:add_user)) != true
  puts "NOTE: Can't find AccountManager for this platform, #{__FILE__}"
else
  describe AutomateIt::AccountManager do
    before(:all) do
      ### @independent = true
      @independent = false

      ### @a = AutomateIt.new(:verbosity => Logger::INFO)
      @a = AutomateIt.new(:verbosity => Logger::WARN)
      @m = @a.account_manager
      @quiet = ! @a.log.info?

      # Some OSes are limited to 8 character names :(
      @username =  "aitestus"
      @groupname = "aitestgr"
      @password = "WejVotyejik2"

      begin
        raise "User named '#{@username}' found. If this isn't a real user, delete it so that the test can contineu. If this is a real user, change the spec to test with a user that shouldn't exist." if @m.users[@username]
        raise "Group named '#{@groupname}' found. If this isn't a real group, delete it so that the test can contineu. If this is a real group, change the spec to test with a group that shouldn't exist." if @m.groups[@groupname]
      rescue Exception => e
        @fail = true
        raise e
      end
    end

    after(:all) do
      unless @fail
        @m.remove_user(@username, :quiet => true)
        @m.remove_group(@username, :quiet => true)
        @m.remove_group(@groupname, :quiet => true)
      end
    end

    after(:each) do
      unless @fail
        if @independent
          @m.remove_user(@username, :quiet => true)
          @m.remove_group(@username, :quiet => true)
          @m.remove_group(@groupname, :quiet => true)
        end
      end
    end

    def add_user(opts={})
      # SunOS /home entries don't exist until you add them to auto_home, so
      # work around this by using a directory we know can be used
      home = INTERPRETER.tagged?(:sunos) ? "/var/tmp/#{@username}" : nil

      defaults = { :passwd => "skosk8osWu", :shell => "/bin/false", :home => home,
        :quiet => @quiet }

      return @m.add_user(@username, defaults.merge(opts))
    end

    def add_group
      return @m.add_group(@groupname)
    end

    def add_user_with_group
      add_user
      return @m.add_group(@groupname, :members => @username)
    end

    it "should find root user" do
      entry = @m.users["root"]
      entry.should_not be_nil
      entry.uid.should == 0
    end

    it "should not have a user before one is created" do
      @m.has_user?(@username).should be_false
    end

    it "should fail to change the password for a non-existent user" do
      lambda{ @m.passwd(@username, "foo") }.should raise_error(ArgumentError)
    end

    it "should create a user" do
      entry = add_user

      entry.should_not be_nil
      entry.name.should == @username
    end

    it "should have a user after one is created" do
      add_user if @independent

      @m.has_user?(@username).should be_true
    end

    it "should query user data by name" do
      add_user if @independent

      entry = @m.users[@username]
      entry.should_not be_nil
      entry.name.should == @username
    end

    it "should query user data by id" do
      add_user if @independent

      uid = @m.users[@username].uid

      entry = @m.users[uid]
      entry.should_not be_nil
      entry.name.should == @username
    end

    it "should not query user data by invalid type" do
      lambda{ @m.users[false] }.should raise_error(TypeError)
    end

    it "should create user group" do
      add_user if @independent

      @m.groups[@username].should_not be_nil
    end

    it "should not re-add an existing user" do
      add_user if @independent

      @m.add_user(@username).should be_false
    end

    it "should not have a non-existent group" do
      @m.has_group?(@groupname).should be_false
    end

    it "should add a group" do
      entry = add_group

      entry.should_not be_nil
      entry.name.should == @groupname
    end

    it "should not re-add a group" do
      add_group if @independent

      @m.add_group(@groupname).should be_false
    end

    it "should query group data by name" do
      add_group if @independent

      entry = @m.groups[@groupname]
      entry.should_not be_nil
      entry.name.should == @groupname
    end

    it "should query group data by id" do
      add_group if @independent
      gid = @m.groups[@groupname].gid

      entry = @m.groups[gid]
      entry.should_not be_nil
      entry.name.should == @groupname
    end

    it "should not query group data by invalid type" do
      lambda{ @m.groups[false] }.should raise_error(TypeError)
    end

    it "should remove a group" do
      add_group if @independent

      @m.remove_group(@groupname).should be_true
    end

    it "should not remove a non-existent group" do
      @m.remove_group(@groupname).should be_false
    end

    it "should not have members for a non-existent group" do
      @m.users_for_group(@groupname).should == []
    end

   it "should add a group with members" do
     add_user_with_group.should_not be_nil
   end

   it "should query users in a group" do
     add_user_with_group if @independent

     @m.users_for_group(@groupname).should == [@username]
   end

   it "should query groups for a user" do
     add_user_with_group if @independent

     @m.groups_for_user(@username).should include(@groupname)
   end

   it "should remove users from a group" do
     add_user_with_group if @independent

     @m.remove_users_from_group(@username, @groupname).should == [@username]
   end

    it "should add groups to a user" do
      add_user if @independent
      add_group if @independent

      @m.add_groups_to_user(@groupname, @username).should == [@groupname]

    end

    it "should add users to group" do
      @m.remove_groups_from_user(@groupname, @username) unless @independent
      add_user if @independent
      add_group if @independent

      @m.add_users_to_group(@username, @groupname).should == [@username]
    end

    it "should remove groups from user" do
      add_user_with_group if @independent

      @m.remove_groups_from_user(@groupname, @username).should == [@groupname]
    end

    it "should remove a group with members" do
      add_group if @independent

      @m.remove_group(@groupname).should be_true
    end

    it "should not add users to non-existent group" do
      lambda{ @m.add_users_to_group(@username, @groupname) }.should raise_error(ArgumentError)
    end

    it "should pretend to add users to non-existent group in preview mode" do
      begin
        @a.preview = true
        @m.add_users_to_group(@username, @groupname).should == [@username]
      ensure
        @a.preview = false
      end
    end

    it "should not remove users from non-existent group" do
      lambda{ @m.remove_users_from_group(@username, @groupname) }.should raise_error(ArgumentError)
    end

    it "should pretend to remove users from non-existent group in preview mode" do
      begin
        @a.preview = true
        @m.remove_users_from_group(@username, @groupname).should == [@username]
      ensure
        @a.preview = false
      end
    end

    def change_password_with(object)
      add_user if @independent

      def extract_pwent(username)
        # TODO Not portable.
        for filename in %w(/etc/master.passwd /etc/shadow /etc/passwd)
          next unless File.exist?(filename)
          return File.read(filename).split(/\n/).grep(/^#{username}\b/)
        end

        # Fails on SunOS which returns "x"
        #::Etc.getpwnam(username).passwd
      end

      before = extract_pwent(@username)
      object.passwd(@username, @password, :quiet => @quiet).should be_true
      after = extract_pwent(@username)

      before.should_not == after
    end

    it "should change password with default driver" do
      change_password_with(@m)
    end

    if INTERPRETER.account_manager[:passwd_pty].available?
      it "should change password with PTY driver" do
        change_password_with(@m[:passwd_pty])
      end
    else
      puts "NOTE: Can't check AccountManager::PasswdPTY on this platform, #{__FILE__}"
    end

    if INTERPRETER.account_manager[:passwd_expect].available?
      it "should change password with Expect driver" do
        change_password_with(@m[:passwd_expect])
      end
    else
      puts "NOTE: Can't check AccountManager::PasswdExpect on this platform, #{__FILE__}"
    end

    it "should fail to change the password when given invalid arguents" do
      lambda{ @m.passwd(Hash.new, "foo") }.should raise_error(TypeError)
    end

    it "should remove a user" do
      add_user if @independent
      @m.remove_user(@username, :quiet => true).should be_true
    end

    it "should not remove a non-existent user" do
      @m.remove_user(@username).should be_false
    end

    it "should add user with multiple groups" do
      # Find the first few users
      groups_expected = []
      size = 3
      Etc.group do |group|
        groups_expected << group.name
        break if groups_expected.size >= size
      end

      # Create a user
      (user = add_user(:groups => groups_expected)).should_not be_true

      # Make sure they have the right number of groups
      groups_found = @m.groups_for_user(@username)
      for group in groups_expected
        ### puts "%s : %s" % [group, groups_found.include?(group)]
        groups_found.should include(group)
      end
    end
  end
end
