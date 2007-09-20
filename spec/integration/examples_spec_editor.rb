require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

# This spec edits the recipes to make them run silently when used with an internal invoke. Although this is faster and more portable, it's also evil and brittle because it can't run the recipes as they are.

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

    begin
      # Preview examples to cause a NotImplemented error on unsupported platforms
      AutomateIt::invoke(params[:installer], :verbosity => Logger::WARN, :preview => true)

      it "should install the example" do
        INTERPRETER.instance_eval do
          mktemp do |recipe|
            log.silence(Logger::WARN) do
              cp(params[:installer], recipe)
              edit(:file => recipe) do
                replace 'service_manager.start\("myapp_server"\)$',
                  'service_manager.start "myapp_server", :silent => true'
                replace 'sh\("rails --database=sqlite3 . > /dev/null"\)',
                  'sh("rails --database=sqlite3 . > /dev/null 2>&1")'
                replace 'sh\("rake db:migrate"\)',
                  'sh("rake db:migrate > /dev/null 2>&1")'
              end or raise "couldn't edit installer"
              # cp recipe, "/tmp/installer.rb"

              AutomateIt::invoke(recipe, :project => params[:project],
                :verbosity => Logger::WARN)
              File.exists?("/etc/init.d/myapp_server").should be_true
              File.directory?("/tmp/myapp_server").should be_true
              service_manager.started?("myapp_server", :wait => 5).should be_true
            end
          end
        end
      end

      it "should uninstall the example" do
        INTERPRETER.instance_eval do
          mktemp do |recipe|
            log.silence(Logger::WARN) do
              cp(params[:uninstaller], recipe)
              edit(:file => recipe) do
                replace 'service_manager.stop "myapp_server"$',
                  'service_manager.stop "myapp_server", :silent => true'
              end or raise "couldn't edit uninstaller"
              ### cp recipe, "/tmp/uninstaller.rb"

              AutomateIt::invoke(recipe, :project => params[:project],
                :verbosity => Logger::WARN)
              File.exists?("/etc/init.d/myapp_server").should be_false
              File.directory?("/tmp/myapp_server").should be_false
              service_manager.stopped?("myapp_server", :wait => 5).should be_true
            end
          end
        end
      end
    rescue NotImplementedError
      puts "NOTE: Can't check examples on this platform, #{__FILE__}"
    end
  end
end
