require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

describe AutomateIt::CLI, " stand-alone" do# {{{
  it "should eval code" do
    AutomateIt::CLI.run(:eval => "42").should == 42
  end

  it "should invoke a recipe" do
    INTERPRETER.mktemp do |filename|
      File.open(filename, "w+") {|h| h.write("42")}
      AutomateIt::CLI.run(:recipe => filename).should == 42
    end
  end
end# }}}

describe AutomateIt::CLI, " without a project" do# {{{
  def on_recipe(opts={})
    INTERPRETER.mktempdircd do
      recipe = "recipe.rb"
      File.open(recipe, "w+"){|h| h.write("42")}
      args = [recipe]
      args << opts unless opts.blank?
      return AutomateIt::CLI.run(*args)
    end
  end

  it "should run recipe with a guessed but non-existent project path" do
    on_recipe().should == 42
  end
  it "should fail to run recipe with explicit but non-existent project path" do
    lambda{ on_recipe(:project => "not_a_real_project") }.should raise_error(ArgumentError)
  end
end# }}}

describe AutomateIt::CLI, " with a project" do# {{{
  def with_project(&block)
    INTERPRETER.mktempdircd do
      project = "myproject"
      AutomateIt::CLI.run(:create => project, :verbosity => Logger::WARN)

      INTERPRETER.cd project do
        block.call(project)
      end
    end
  end

  it "should create a project" do
    with_project do
      File.exists?("config/tags.yml").should be_true
    end
  end

  it "should invoke a project recipe that can access a dist directory" do
    with_project do
      recipe =  "recipes/recipe.rb"
      write_to(recipe, "dist")

      path = AutomateIt::CLI.run(:recipe => recipe)
      File.expand_path(path).should == File.expand_path("./dist")
    end
  end

  it "should load custom driver" do
    with_project do
      recipe = "recipes/recipe.rb"
      driver = "lib/custom_driver.rb"

      write_to(driver, <<-HERE)
        class ::AutomateIt::PackageManager::MyDriver < ::AutomateIt::PackageManager::BaseDriver
          depends_on :nothing

          def suitability(method, *args) # :nodoc:
            # Never select as default driver
            return 0
          end
        end
      HERE

      write_to(recipe, <<-HERE)
        package_manager.drivers.keys.include?(:my_driver)
      HERE

      AutomateIt::CLI.run(:recipe => recipe).should be_true
    end
  end

  it "should load custom driver with a different namespace than its manager" do
    with_project do
      recipe = "recipes/recipe.rb"
      driver = "lib/custom_driver.rb"

      # Keep this in sync with rdoc example in: lib/automateit/plugins/driver.rb
      write_to(driver, <<-HERE)
        class MyOtherDriver < ::AutomateIt::PackageManager::BaseDriver
          depends_on :nothing

          def suitability(method, *args) # :nodoc:
            # Never select as default driver
            return 0
          end
        end
      HERE

      write_to(recipe, <<-HERE)
        package_manager.drivers.keys.include?(:my_other_driver)
      HERE

      AutomateIt::CLI.run(:recipe => recipe).should be_true
    end
  end

  it "should load tags in a project" do
    with_project do
      recipe = "recipes/recipe.rb"
      tags_yml = "config/tags.yml"

      write_to(tags_yml, <<-HERE)
        all_servers:
          - localhost
        all_groups:
          - @all_servers
        no_servers:
          - !localhost
        no_groups:
          - !@all_servers
      HERE

      write_to(recipe, <<-HERE)
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

  it "should add run-time tags to a project" do
    with_project do
      recipe = "recipes/recipe.rb"

      write_to(recipe, <<-HERE)
        tagged?("added")
      HERE

      AutomateIt::CLI.run(:recipe => recipe, :tags => %w(added)).should be_true
    end
  end

  it "should add run-time tags to a project without masking existing tags" do
    with_project do
      recipe = "recipes/recipe.rb"
      tags_yml = "config/tags.yml"

      write_to(tags_yml, <<-HERE)
        all_servers:
          - localhost
      HERE

      write_to(recipe, <<-HERE)
        tagged?("added && all_servers")
      HERE

      AutomateIt::CLI.run(:recipe => recipe, :tags => %w(added)).should be_true
    end
  end

  it "should load fields in a project" do
    with_project do
      recipe = "recipes/recipe.rb"
      fields = "config/fields.yml"

      write_to(fields, <<-HERE)
        <%="key"%>: value
        hash:
          leafkey: leafvalue
          branchkey:
            deepleafkey: deepleafvalue
      HERE

      write_to(recipe, <<-HERE)
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
    with_project do
      first = "recipes/first.rb"
      second = "recipes/second.rb"

      write_to(first, "invoke 'second'")
      write_to(second, "42")

      AutomateIt::CLI.run(first).should == 42
    end
  end

  it "should be able to run default project" do
    with_project do
      # XXX How to determine which rake to use!?
      rake = RUBY_PLATFORM =~ /mswin/i ? "rake.bat" : "rake" 
      output = `#{rake} -I #{AutomateIt_Lib} preview hello`
      output.should match(/I'm in preview mode/)
    end
  end
end# }}}

describe AutomateIt::CLI, " with an interactive shell" do# {{{
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
end# }}}
