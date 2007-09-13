require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

# This spec runs the ruby interpreter directly. This makes it possible to silently run the recipes, without editing them. Unfortunately, this is evil and brittle because it relies on being able to run the interpreter again. The alternative is "spec/integration/examples_spec_editor.rb", which edits the recipes so they're silent and uses the internal invoke method to run them. What's a reasonable way to do this?

if not INTERPRETER.superuser?
  puts "NOTE: Must be root to check #{__FILE__}"
else
  describe "Examples" do
    params = {
      :project => "examples/basic",
      :installer => "examples/basic/recipes/install.rb",
      :uninstaller => "examples/basic/recipes/uninstall.rb",
    }
    INTERPRETER.params = params

    # Get the fully qualified filename for the interpreter.
    # XXX What bad things will this do if, say, running with JRuby?
    ruby = begin
      c = ::Config::CONFIG
      File::join(c['bindir'], c['ruby_install_name']) << c['EXEEXT']
    end

    begin
      # This will throw a NotImplemented error on unsupported platforms
      AutomateIt::invoke(params[:installer], :verbosity => Logger::WARN, :noop => true)

      it "should install the example" do
        INTERPRETER.instance_eval do
          log.silence(Logger::WARN) do
            sh("#{ruby} bin/automateit #{params[:installer]} > /dev/null 2>&1")
            File.exists?("/etc/init.d/myapp_server").should be_true
            File.directory?("/tmp/myapp_server").should be_true
            service_manager.started?("myapp_server", :wait => 5).should be_true
          end
        end
      end

      it "should uninstall the example" do
        INTERPRETER.instance_eval do
          log.silence(Logger::WARN) do
            sh("#{ruby} bin/automateit #{params[:uninstaller]} > /dev/null 2>&1")
            File.exists?("/etc/init.d/myapp_server").should be_false
            File.directory?("/tmp/myapp_server").should be_false
            service_manager.stopped?("myapp_server", :wait => 5).should be_true
          end
        end
      end
    rescue NotImplementedError
      puts "NOTE: Can't check examples on this platform, #{__FILE__}"
    end
  end
end
