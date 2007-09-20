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
    # FIXME this seems to break IRB somehow for breakpoints, why?!
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

  it "should load custom driver" do
    INTERPRETER.mktempdircd do
      project = "myproject"
      recipe = File.join(project, "recipes", "recipe.rb")
      driver = File.join(project, "lib", "custom_driver.rb")
      AutomateIt::CLI.run(:create => project, :verbosity => Logger::WARN)

      # Keep this in sync with rdoc example in: lib/automateit/plugins/driver.rb
      File.open(driver, "w+"){|h| h.write(<<-HERE)}
        class ::AutomateIt::PackageManager::MyDriver < ::AutomateIt::PackageManager::BaseDriver
          depends_on :nothing

          def suitability(method, *args) # :nodoc:
            # Never select as default driver
            return 0
          end
        end
      HERE

      File.open(recipe, "w+"){|h| h.write(<<-HERE)}
        package_manager.drivers.keys.include?(:my_driver)
      HERE

      AutomateIt::CLI.run(:recipe => recipe).should be_true
    end
  end

  it "should load custom driver that's in a different namespace from its manager" do
    INTERPRETER.mktempdircd do
      project = "myproject"
      recipe = File.join(project, "recipes", "recipe.rb")
      driver = File.join(project, "lib", "custom_driver.rb")
      AutomateIt::CLI.run(:create => project, :verbosity => Logger::WARN)

      # Keep this in sync with rdoc example in: lib/automateit/plugins/driver.rb
      File.open(driver, "w+"){|h| h.write(<<-HERE)}
        class MyOtherDriver < ::AutomateIt::PackageManager::BaseDriver
          depends_on :nothing

          def suitability(method, *args) # :nodoc:
            # Never select as default driver
            return 0
          end
        end
      HERE

      File.open(recipe, "w+"){|h| h.write(<<-HERE)}
        package_manager.drivers.keys.include?(:my_other_driver)
      HERE

      AutomateIt::CLI.run(:recipe => recipe).should be_true
    end
  end

  it "should load tags in a project" do
    INTERPRETER.mktempdircd do
      project = "myproject"
      recipe = File.join(project, "recipes", "recipe.rb")
      tags_yml = File.join(project, "config", "tags.yml")
      AutomateIt::CLI.run(:create => project, :verbosity => Logger::WARN)

      File.open(tags_yml, "w+"){|h| h.write(<<-HERE)}
        all_servers:
          - localhost
        all_groups:
          - @all_servers
        no_servers:
          - !localhost
        no_groups:
          - !@all_servers
      HERE

      File.open(recipe, "w+"){|h| h.write(<<-HERE)}
        result = true
        result &= tagged?("localhost")
        result &= tagged?("all_servers")
        result &= tagged?("all_groups")
        result &= ! tagged?("no_servers")
        result &= ! tagged?("no_groups")

        result
      HERE

      AutomateIt::CLI.run(:recipe => recipe).should be_true
    end
  end

  it "should load fields in a project" do
    INTERPRETER.mktempdircd do
      project = "myproject"
      recipe = File.join(project, "recipes", "recipe.rb")
      fields = File.join(project, "config", "fields.yml")
      AutomateIt::CLI.run(:create => project, :verbosity => Logger::WARN)

      File.open(fields, "w+"){|h| h.write(<<-HERE)}
        <%="key"%>: value
        hash:
          leafkey: leafvalue
          branchkey:
            deepleafkey: deepleafvalue
      HERE

      File.open(recipe, "w+"){|h| h.write(<<-HERE)}
        lookup("*") 
        lookup("key")
        lookup("hash")
        lookup("hash")["leafkey"]
        lookup("hash#leafkey")
        lookup("hash#branchkey#deepleafkey")
        lookup("asdf") rescue IndexError
        true
      HERE

      AutomateIt::CLI.run(:recipe => recipe).should be_true
    end
  end

  it "should let recipes invoke other recipes" do
    INTERPRETER.mktempdircd do
      project = "myproject"
      first = File.join(project, "recipes", "first.rb")
      second = File.join(project, "recipes", "second.rb")
      AutomateIt::CLI.run(:create => project, :verbosity => Logger::WARN)

      File.open(first, "w+"){|h| h.write(<<-HERE)}
        invoke 'second'
      HERE

      File.open(second, "w+"){|h| h.write(<<-HERE)}
        42
      HERE

      AutomateIt::CLI.run(first).should == 42
    end
  end

  it "should be able to run default project" do
    INTERPRETER.mktempdircd do
      project = "myproject"
      AutomateIt::CLI.run(:create => project, :verbosity => Logger::WARN)

      INTERPRETER.cd project do
        output = `rake -I #{AutomateIt_Lib} preview hello`
        output.should match(/I'm in preview mode/)
      end
    end
  end
end

describe AutomateIt::CLI, " without a project" do
  def on_recipe(&block)
    INTERPRETER.mktempdircd do
      recipe = "recipe.rb"
      File.open(recipe, "w+"){|h| h.write("42")}
      block.call(recipe)
    end
  end

  it "should not fail to run a recipe with a non-existent guessed project path" do
    on_recipe do |recipe|
      AutomateIt::CLI.run(recipe).should == 42
    end
  end
  it "should fail to run a recipe with an non-existent but explicit project path" do
    on_recipe do |recipe|
      lambda{ AutomateIt::CLI.run(recipe, :project => "not_a_real_project")}.should raise_error(ArgumentError)
    end
  end
end
