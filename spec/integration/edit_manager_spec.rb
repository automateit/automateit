require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

describe "AutomateIt::EditManager for files" do
  before :all do
    @a = AutomateIt.new(:verbosity => Logger::WARN)
  end

  it "should make a backup if editing a file" do
    @a.mktempdircd do
      target = "myfile"
      @a.render(:text => "Whatever", :to => target)
      entries = Dir.entries(".").select{|t| t =~ /^#{target}/}
      entries.size.should == 1
      
      @a.edit(:file => target) do
        append "Hello"
      end.should be_true
      
      entries = Dir.entries(".").select{|t| t =~ /^#{target}/}
      entries.size.should == 2
      File.size(entries[0]).should_not == File.size(entries[1])
    end    
  end

  it "should not make a backup if not editing a file" do
    @a.mktempdircd do
      target = "myfile"
      @a.render(:text => "Whatever", :to => target)
      entries = Dir.entries(".").select{|t| t =~ /^#{target}/}
      entries.size.should == 1
      
      @a.edit(:file => target) do
      end.should be_false
      
      entries = Dir.entries(".").select{|t| t =~ /^#{target}/}
      entries.size.should == 1
    end    
  end
  
  it "should not make a backup for a newly created file" do
    @a.mktempdircd do
      target = "myfile"
      
      @a.edit(:file => target, :create => true) do
        append "Hello"
      end.should be_true
      
      entries = Dir.entries(".").select{|t| t =~ /^#{target}/}
      entries.size.should == 1
    end  
  end
end
