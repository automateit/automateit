require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

describe "AutomateIt::TemplateManager::ERB" do
  before(:all) do
    @a = AutomateIt.new(:verbosity => Logger::WARN)
    @m = @a.template_manager
    @d = @m[:erb]

    @source = "source_for_template"
    @target = "target_for_template"
  end

  after(:each) do
    if File.exists?(@target)
      File.unlink(@target)
      raise "A write wasn't intercepted by the mocks! Removing file and giving up."
    end
  end

  it "should render a string template" do
    @d.should_receive(:_exists?).once.with(@target).and_return(false)
    @d.should_receive(:_write).once.with(@target, "my template content").and_return(true)

    @a.render(:string => "my template content", :to => @target).should be_true
  end

  it "should render a file template" do
    @d.should_receive(:_exists?).once.with(@target).and_return(false)
    @d.should_receive(:_read).once.with(@source).and_return("my template content")
    @d.should_receive(:_write).once.with(@target, "my template content").and_return(true)

    @a.render(@source, @target).should be_true
  end

  it "should render with local variables" do
    @d.should_receive(:_exists?).once.with(@target).and_return(false)
    @d.should_receive(:_read).once.with(@source).and_return("hello <%=entity%>")
    @d.should_receive(:_write).once.with(@target, "hello world").and_return(true)

    @a.render(@source, @target, :locals => {:entity => "world"}).should be_true
  end

  it "should render when the template was updated" do
    timestamp = Time.now
    @d.should_receive(:_exists?).once.with(@target).and_return(true)
    @d.should_receive(:_read).once.with(@target).and_return("my old content")
    @d.should_receive(:_read).once.with(@source).and_return("my template content")
    @d.should_receive(:_mtime).once.with(@source).and_return(timestamp+1)
    @d.should_receive(:_mtime).once.with(@target).and_return(timestamp)
    @d.should_receive(:_write).once.with(@target, "my template content").and_return(true)

    @a.render(@source, @target, :check => :timestamp).should be_true
  end

  it "shouldn't render when the template wasn't updated" do
    timestamp = Time.now
    @d.should_receive(:_exists?).once.with(@target).and_return(true)
    @d.should_receive(:_mtime).once.with(@source).and_return(timestamp)
    @d.should_receive(:_mtime).once.with(@target).and_return(timestamp+1)

    @a.render(@source, @target, :check => :timestamp).should be_false
  end

  it "should render when the template's dependencies are updated" do
    timestamp = Time.now
    @d.should_receive(:_exists?).once.with(@target).and_return(true)
    @d.should_receive(:_read).once.with(@target).and_return("my old content")
    @d.should_receive(:_read).once.with(@source).and_return("my template content")
    @d.should_receive(:_mtime).once.with("foo").and_return(timestamp+1)
    @d.should_receive(:_mtime).once.with(@source).and_return(timestamp)
    @d.should_receive(:_mtime).once.with(@target).and_return(timestamp)
    @d.should_receive(:_write).once.with(@target, "my template content").and_return(true)

    @a.render(@source, @target, :check => :timestamp, :dependencies => ["foo"]).should be_true
  end

  it "shouldn't render when the template's dependencies weren't updated" do
    timestamp = Time.now
    @d.should_receive(:_exists?).once.with(@target).and_return(true)
    @d.should_receive(:_mtime).once.with("foo").and_return(timestamp)
    @d.should_receive(:_mtime).once.with(@source).and_return(timestamp)
    @d.should_receive(:_mtime).once.with(@target).and_return(timestamp+1)

    @a.render(@source, @target, :check => :timestamp, :dependencies => ["foo"]).should be_false
  end

  it "should render when forced even if the template wasn't updated" do
    @d.should_receive(:_exists?).once.with(@target).and_return(true)
    @d.should_receive(:_read).once.with(@target).and_return("my old content")
    @d.should_receive(:_read).once.with(@source).and_return("my template content")
    @d.should_receive(:_write).once.with(@target, "my template content").and_return(true)

    @a.render(@source, @target, :check => :timestamp, :dependencies => ["foo"], :force => true).should be_true
  end

  it "should render if told to check the existence of output and it doesn't exist" do
    @d.should_receive(:_exists?).once.with(@target).and_return(false)
    @d.should_receive(:_read).once.with(@source).and_return("my template content")
    @d.should_receive(:_write).once.with(@target, "my template content").and_return(true)

    @a.render(@source, @target, :check => :exists).should be_true
  end

  it "shouldn't render if told to check the existence of output and it exists" do
    @d.should_receive(:_exists?).once.with(@target).and_return(true)

    @a.render(@source, @target, :check => :exists).should be_false
  end

  it "should render if told to compare if the output is different" do
    @d.should_receive(:_exists?).once.with(@target).and_return(true)
    @d.should_receive(:_read).once.with(@target).and_return("my old content")
    @d.should_receive(:_read).once.with(@source).and_return("my template content")
    @d.should_receive(:_write).once.with(@target, "my template content").and_return(true)

    @a.render(@source, @target, :check => :compare).should be_true
  end

  it "shouldn't render if told to compare if the output is the same" do
    @d.should_receive(:_exists?).once.with(@target).and_return(true)
    @d.should_receive(:_read).once.with(@target).and_return("my template content")
    @d.should_receive(:_read).once.with(@source).and_return("my template content")

    @a.render(@source, @target, :check => :compare).should be_false
  end
end
