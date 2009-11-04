require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

describe "AutomateIt::DownloadManager" do
  before :all do
    @a = AutomateIt.new(:verbosity => Logger::WARN)
    @source = "http://www.google.com/"
    @match = /search/mi
  end

  it "should download a web page to a file" do
    @a.mktempdircd do
      target = "google.html"

      @a.download(@source, :to => target).should be_true

      File.exists?(target).should be_true
      File.read(target).should =~ @match
    end
  end

  it "should download a web page to a specific directory" do
    @a.mktempdircd do
      directory = "."
      target = File.join(directory, "www.google.com")

      @a.download(@source, :to => directory).should be_true

      File.exists?(target).should be_true
      File.read(target).should =~ @match
    end
  end

  it "should download a web page by default to current directory" do
    @a.mktempdircd do
      target = "www.google.com"

      @a.download(@source).should be_true

      File.exists?(target).should be_true
      File.read(target).should =~ @match 
    end
  end
end
