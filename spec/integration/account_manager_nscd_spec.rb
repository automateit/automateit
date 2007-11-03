require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

if not INTERPRETER.euid?
  puts "NOTE: Can't check 'euid' on this platform, #{__FILE__}"
elsif not INTERPRETER.superuser?
  puts "NOTE: Must be root to check #{__FILE__}"
elsif not INTERPRETER.account_manager.available?(:invalidate)
  puts "NOTE: Can't check AccountManager::NSCD on this platform, #{__FILE__}"
else
  describe AutomateIt::AccountManager::NSCD do
    before(:all) do
      @a = AutomateIt.new(:verbosity => Logger::WARN)
      @m = @a.account_manager
      @d = @m[:nscd]
    end

    it "should know what NSCD databases are associated with passwd" do
      for query in %w(user users passwd password)
        @d.database_for(query).should == :passwd
      end
    end

    it "should know what NSCD databases are associated with group" do
      for query in %w(group groups)
        @d.database_for(query).should == :group
      end
    end

    it "should fail with invalid queries" do
      lambda { @d.database_for(:stuff) }.should raise_error(ArgumentError)
    end

    it "should invalidate NSCD databases" do
      @m.invalidate(:passwd).should be_true
    end
  end
end
