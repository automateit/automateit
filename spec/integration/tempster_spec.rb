require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

describe Tempster do
  it "should create a temporary file" do
    result = nil
    begin
      result = Tempster.mktemp(:verbose => false)
      File.exists?(result).should be_true
    ensure
      File.unlink(result) if result
    end
  end

  it "should create a temporary file and remove it with a block" do
    result = nil
    begin
      Tempster.mktemp(:verbose => false) do |path|
        result = path
        File.exists?(result).should be_true
      end
      File.exists?(result).should be_false
    ensure
      File.unlink(result) if result and File.exists?(result)
    end
  end

  it "should create a temporary directory" do
    result = nil
    begin
      result = Tempster.mktempdir(:verbose => false)
      File.directory?(result).should be_true
    ensure
      Dir.rmdir(result) if result
    end
  end

  it "should create a temporary directory and remove it with a block" do
    result = nil
    begin
      Tempster.mktempdir(:verbose => false) do |path|
        result = path
        File.directory?(result).should be_true
      end
      File.directory?(result).should be_false
    ensure
      Dir.rmdir(result) if result and File.directory?(result)
    end
  end

  it "should create a temporary directory, cd into it and remove it with a block" do
    result = nil
    previous = Dir.pwd
    begin
      Tempster.mktempdircd(:verbose => false) do |path|
        result = path
        File.directory?(result).should be_true
        Dir.pwd.should_not == previous
      end
      File.directory?(result).should be_false
      Dir.pwd.should == previous
    ensure
      Dir.rmdir(result) if result and File.directory?(result)
    end
  end
end
