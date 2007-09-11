require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

describe "AutomateIt::CLI" do
  it "should create a project" do
    INTERPRETER.mktempdircd do
      project = "myproject"
      AutomateIt::CLI.run(:create => project, :verbosity => Logger::WARN)
      File.directory?(project).should be_true
      File.exists?(File.join(project, "config", "tags.yml")).should be_true
    end
  end

  it "should eval code" do
    AutomateIt::CLI.run(:eval => "42").should == 42
  end

  it "should invoke a recipe" do
    INTERPRETER.mktemp do |filename|
      File.open(filename, "w+") {|h| h.write("42")}
      AutomateIt::CLI.run(:recipe => filename).should == 42
    end
  end

  it "should invoke a project recipe that can access a dist directory" do
    INTERPRETER.mktempdircd do
      project = "myproject"
      recipe = File.join(project, "recipes", "recipe.rb")
      AutomateIt::CLI.run(:create => project, :verbosity => Logger::WARN)
      File.open(recipe, "w+") {|h| h.write("dist")}
      path = AutomateIt::CLI.run(:recipe => recipe)
      File.expand_path(path).should == File.expand_path(File.join(project, "dist"))
    end
  end

  it "should provide an interactive shell" do
    # Mock IRB to run shell and return it to unmocked state when done
    begin
      $irb_under_test = true
      require 'irb'
      IRB::Irb.class_eval do
        def initialize_with_test(*args)
          return initialize_without_test(*args) unless $irb_under_test

          require 'spec'
          @context = Spec::Mocks::Mock.new("asdf", :null_object => true)
          self.instance_eval { def eval_input; 42; end }
        end
        alias_method_chain :initialize, :test
      end
      AutomateIt::CLI.run(:verbosity => Logger::WARN).should == 42
    ensure
      $irb_under_test = false
    end
  end

  it "should provide recipes with access to a custom driver" do
    INTERPRETER.mktempdircd do
      project = "myproject"
      recipe = File.join(project, "recipes", "recipe.rb")
      driver = File.join(project, "lib", "custom_driver.rb")
      AutomateIt::CLI.run(:create => project, :verbosity => Logger::WARN)
      File.open(recipe, "w+"){|h| h.write("package_manager.drivers.keys.include?(:my_driver)")}
      # Keep this in sync with rdoc example in: lib/automateit/plugins/driver.rb
      File.open(driver, "w+"){|h| h.write(<<-EOB)}
        class ::AutomateIt::PackageManager::MyDriver < ::AutomateIt::PackageManager::AbstractDriver
          depends_on :nothing

          def suitability(method, *args) # :nodoc:
            # Never select as default driver
            return 0
          end
        end
      EOB
      rv = AutomateIt::CLI.run(:recipe => recipe)
      rv.should be_true
    end
  end
end
