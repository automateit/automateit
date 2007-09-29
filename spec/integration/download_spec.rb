require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

describe "AutomateIt::DownloadManager" do
  before :all do
    @a = AutomateIt.new(:verbosity => Logger::WARN)
  end

  it "should download a web page to a file" do
    @a.mktempdircd do
      source = "http://www.google.com/"
      target = "google.html"

      @a.download(source, :to => target).should be_true

      File.exists?(target).should be_true
      File.read(target).should =~ /<html>.*Google/im
    end
  end

  it "should download a web page to a directory" do
    @a.mktempdircd do
      source = "http://www.google.com/"
      intermediate = "."
      target = "www.google.com"

      @a.download(source, :to => intermediate).should be_true

      File.exists?(target).should be_true
      File.read(target).should =~ /<html>.*Google/im
    end
  end

  it "should download a web page to current directory" do
    @a.mktempdircd do
      source = "http://www.google.com/"
      target = "www.google.com"

      @a.download(source).should be_true

      File.exists?(target).should be_true
      File.read(target).should =~ /<html>.*Google/im
    end
  end
end
