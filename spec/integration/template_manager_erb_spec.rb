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
      mode1 = 0646 if INTERPRETER.shell_manager.provides_mode?
      mode2 = 0100646
      File.open(source, "w+"){|h| h.write("<%=variable%>")}

      opts = {:file => source, :to => target, :locals => {:variable => 42}}
      opts[:mode] = mode1 if mode1
      @a.render(opts).should be_true
      File.read(target).should == "42"
      if INTERPRETER.shell_manager.provides_mode?
        File.stat(target).mode.should == mode2
      else
        puts "NOTE: Can't check permission modes on this platform, #{__FILE__}"
      end
    end
  end
end
