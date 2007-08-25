require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

if not INTERPRETER.superuser?
  puts "NOTE: Must be root to check #{__FILE__}"
elsif not INTERPRETER.account_manager.available?(:add_user)
  puts "NOTE: Can't find AccountManager for this platform in #{__FILE__}"
else
  describe "AutomateIt::AccountManager" do
    before(:all) do
      @a = AutomateIt.new(:verbosity => Logger::WARN)
      #@a = AutomateIt.new(:verbosity => Logger::DEBUG)
      @m = @a.account_manager

      @username = "asdfasdf"
      @groupname = "fdsafdsa"

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
      entry = @m.add_user(@username)

      entry.should_not be_nil
      entry.name.should == @username
      # Leaves behind user for further tests
    end

    it "should have a user after one is created" do
      # Depends on user to be created by previous tests
      @m.has_user?(@username).should be_true
    end

    it "should be able to query user data for newly-created user" do
      # Depends on user to be created by previous tests
      entry = @m.users[@username]
      entry.should_not be_nil
      entry.name.should == @username
    end

    it "should have created a group for the user" do
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
    end

    it "should not re-add a group" do
      @m.add_group(@groupname).should be_false
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
      @m.groups_for_user(@username).include?(@groupname).should be_true
    end

    it "should remove users from a group" do
      # Depends on user to be created by previous tests
      # Depends on group to be created by previous tests
      @m.remove_users_from_group(@username, @groupname).should == [@username]
    end

    it "should remove a group with members" do
      # Depends on group to be created by previous tests
      @m.remove_group(@groupname).should be_true
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
