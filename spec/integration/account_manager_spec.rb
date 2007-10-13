require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

if not INTERPRETER.euid?
  puts "NOTE: Can't check 'euid' on this platform, #{__FILE__}"
elsif not INTERPRETER.superuser?
  puts "NOTE: Must be root to check #{__FILE__}"
elsif not INTERPRETER.account_manager.available?(:add_user)
  puts "NOTE: Can't find AccountManager for this platform, #{__FILE__}"
else
  describe AutomateIt::AccountManager do
    before(:all) do
      @independent = true

      #@a = AutomateIt.new(:verbosity => Logger::INFO)
      @a = AutomateIt.new(:verbosity => Logger::WARN)
      @m = @a.account_manager
      @quiet = ! @a.log.info?

      # Some OSes are limited to 8 character names :(
      @username =  "aitestus"
      @groupname = "aitestgr"

      raise "User named '#{@username}' found. If this isn't a real user, delete it so that the test can contineu. If this is a real user, change the spec to test with a user that shouldn't exist." if @m.users[@username]
      raise "Group named '#{@groupname}' found. If this isn't a real group, delete it so that the test can contineu. If this is a real group, change the spec to test with a group that shouldn't exist." if @m.groups[@groupname]
    end

    after(:all) do
      @m.remove_user(@username, :quiet => true)
      @m.remove_group(@username, :quiet => true)
      @m.remove_group(@groupname, :quiet => true)
    end

    after(:each) do
      if @independent
        @m.remove_user(@username, :quiet => true)
        @m.remove_group(@username, :quiet => true)
        @m.remove_group(@groupname, :quiet => true)
      end
    end

    def add_user
      # SunOS /home entries don't exist until you add them to auto_home, so
      # work around this by using a directory we know can be used
      home = \
        if INTERPRETER.tagged?(:sunos)
          require 'tmpdir'
          File.join(Dir.tmpdir, @username)
        else
          nil
        end

      return @m.add_user(@username, :passwd => "asdf", :shell => "/bin/false",
         :home => home, :quiet => @quiet)
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

      @m.add_groups_to_user(@groupname, @username).should == [@groupname]
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

    it "should change password" do
      add_user if @independent
      pass = "automateit"

      # TODO This isn't portable
      def extract_pwent(username)
        for filename in %w(/etc/shadow /etc/passwd)
          next unless File.exist?(filename)
          return File.read(filename).split(/\n/).grep(/^#{username}\b/)
        end
      end

      before = extract_pwent(@username)
      @m.passwd(@username, pass, :quiet => @quiet).should be_true
      after = extract_pwent(@username)
      before.should_not eql(after)
    end

    it "should remove a user" do
      add_user if @independent
      @m.remove_user(@username, :quiet => true).should be_true
    end

    it "should not remove a non-existent user" do
      @m.remove_user(@username).should be_false
    end
  end
end
