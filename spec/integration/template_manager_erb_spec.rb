require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

describe "AutomateIt::TemplateManager::ERB" do
  before(:all) do
    @a = AutomateIt.new(:verbosity => Logger::WARN)
    @m = @a.template_manager
    @d = @m[:erb]
    @d.setup(:default_check => :mtime)
    @d.available?.should be_true
  end

  it "should set mode when rendering" do
    @a.mktempdircd do
      source = "foo"
      target = "bar"
      File.open(source, "w+"){|h| h.write("<%=variable%>")}

      @a.render(:file => source, :to => target, :mode => 0646,
                :locals => {:variable => 42}).should be_true
      File.read(target).should == "42"
      File.stat(target).mode.should == 0100646
    end
  end
end
