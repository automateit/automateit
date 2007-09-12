require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

# Good way to run this to confirm the startup sequence works flawlessly -- this leaves the server running, stops it, and confirms that the :wait works:
#  spec -e "should install the example" spec/integration/examples_spec.rb; /etc/init.d/myapp_server stop; spec -e "should install the example" spec/integration/examples_spec.rb

if not INTERPRETER.superuser?
  puts "NOTE: Must be root to check #{__FILE__}"
else
  describe "Examples" do
    project = "examples/basic"
    installer = "examples/basic/recipes/install.rb"
    uninstaller = "examples/basic/recipes/uninstall.rb"

    begin
      # This will throw a NotImplemented error on unsupported platforms
      AutomateIt::invoke(installer, :verbosity => Logger::WARN, :noop => true)

      it "should install the example" do
        INTERPRETER.mktemp do |recipe|
          INTERPRETER.log.silence(Logger::WARN) do
            INTERPRETER.cp(installer, recipe)
            INTERPRETER.edit(:file => recipe) do
              replace 'service_manager.start\("myapp_server"\)$',
                "service_manager.start 'myapp_server', :silent => true"
            end or raise "couldn't edit installer"
            ### INTERPRETER.cp recipe, "/tmp/installer.rb"

            AutomateIt::invoke(recipe, :project => project, :verbosity => Logger::WARN)
            File.exists?("/etc/init.d/myapp_server").should be_true
            File.directory?("/tmp/myapp_server").should be_true
            INTERPRETER.service_manager.started?("myapp_server", :wait => 5).should be_true
          end
        end
      end

      it "should uninstall the example" do
        INTERPRETER.mktemp do |recipe|
          INTERPRETER.log.silence(Logger::WARN) do
            INTERPRETER.cp(uninstaller, recipe)
            INTERPRETER.edit(:file => recipe) do
              replace 'service_manager.stop "myapp_server"$',
                "service_manager.stop 'myapp_server', :silent => true"
            end or raise "couldn't edit uninstaller"
            ### INTERPRETER.cp recipe, "/tmp/uninstaller.rb"

            AutomateIt::invoke(recipe, :project => project, :verbosity => Logger::WARN)
            File.exists?("/etc/init.d/myapp_server").should be_false
            File.directory?("/tmp/myapp_server").should be_false
            INTERPRETER.service_manager.stopped?("myapp_server", :wait => 5).should be_true
          end
        end
      end
    rescue NotImplementedError
      puts "NOTE: Can't check examples on this platform, #{__FILE__}"
    end
  end
end
