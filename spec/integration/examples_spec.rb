require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

# This spec runs the ruby interpreter directly. This makes it possible to silently run the recipes, without editing them. Unfortunately, this is evil and brittle because it relies on being able to run the interpreter again. The alternative is "spec/integration/examples_spec_editor.rb", which edits the recipes so they're silent and uses the internal invoke method to run them. What's a reasonable way to do this?

if not INTERPRETER.euid?
  puts "NOTE: Can't check 'euid' on this platform, #{__FILE__}"
elsif not INTERPRETER.superuser?
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
    INTERPRETER.params[:ruby] = begin
      c = ::Config::CONFIG
      File::join(c['bindir'], c['ruby_install_name']) << c['EXEEXT']
    end

    def wrap_command(cmd, &block)
      INTERPRETER.instance_eval do
        log.silence(Logger::WARN) do
          output = `#{params[:ruby]} #{cmd} 2>&1`
          begin
            block.call
          rescue Exception => e
            puts "ERROR, failed while running command:\n#{cmd}\n#{output}"
            raise e
          end
        end
      end
    end

    begin
      # Preview examples to cause a NotImplemented error on unsupported platforms
      AutomateIt::invoke(params[:installer], :verbosity => Logger::WARN, :preview => true, :friendly_exceptions => false)

      it "should install the example" do
        wrap_command("bin/automateit #{params[:installer]}") do
          File.exists?("/etc/init.d/myapp_server").should be_true
          File.directory?("/tmp/myapp_server").should be_true
          INTERPRETER.service_manager.started?("myapp_server", :wait => 5).should be_true
        end
      end

      it "should uninstall the example" do
        wrap_command("bin/automateit #{params[:uninstaller]}") do
          File.exists?("/etc/init.d/myapp_server").should be_false
          File.directory?("/tmp/myapp_server").should be_false
          INTERPRETER.service_manager.stopped?("myapp_server", :wait => 5).should be_true
        end
      end
    rescue NotImplementedError => e
      puts "NOTE: Can't check examples on this platform, #{__FILE__}"
    end
  end
end
