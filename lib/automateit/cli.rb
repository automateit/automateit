require "rubygems"
require "active_support"
require "automateit"

module AutomateIt
  # == CLI
  #
  # The CLI class provides AutomateIt's command-line interface. It's
  # responsible for invoking recipes from the command line, starting the
  # interactive shell and creating projects. It's run from
  # <tt>bin/automate</tt>.
  class CLI
    # Create a new CLI interpreter. If no :recipe or :eval option is provided,
    # it starts an interactive IRB session for the Interpreter.
    #
    # Options:
    # * :project - Project directory to load.
    # * :recipe - Recipe file to execute.
    # * :eval - Evaluate this string.
    # * :quiet - Don't print shell header.
    def initialize(opts={})
      opts[:project] ||= opts[:recipe] ? File.join(File.dirname(opts[:recipe]), "..") : "."
      if opts[:create]
        self.class.create_project(opts)
      elsif opts[:recipe]
        interpreter = AutomateIt.new(opts)
        interpreter.invoke(opts[:recipe])
      elsif code = opts.delete(:eval)
        interpreter = AutomateIt.new(opts)
        interpreter.instance_eval(code)
      else
        require "irb"
        unless opts[:quiet]
          puts PNOTE+"AutomateIt Shell v#{AutomateIt::VERSION}"
          puts PNOTE+"<CTRL-D> to quit, <Tab> to auto-complete"
        end
        IRB.setup(__FILE__)
        irb = IRB::Irb.new
        IRB.instance_variable_get(:@CONF)[:MAIN_CONTEXT] = irb.context
        interpreter = AutomateIt.new(opts)
        irb.context.workspace.instance_variable_set(:@binding, interpreter.send(:binding))
        irb.eval_input
      end
    end

    # Create a new project.
    #
    # Options:
    # * :create - Project path to create. Required.
    # * All other options are passed to the AutomateIt::Interpreter.
    def self.create_project(opts)
      path = opts.delete(:create) \
        or raise ArgumentError.new(":create option not specified")
      interpreter = AutomateIt.new(opts)
      interpreter.instance_eval do
        # Make +render+ only generate files only if they don't already exist.
        template_manager.default_check = :exists

        mkdir_p(path) do |created|
          puts PNOTE+"#{created ? 'Creating' : 'Updating'} AutomateIt project at: #{path}"

          mkdir("config") do
            render(:string => TAGS_CONTENT, :to => "tags.yml")
            render(:string => FIELDS_CONTENT, :to => "fields.yml")
            render(:string => ENV_CONTENT, :to => "automateit_env.rb")
          end

          mkdir("dist") do
            render(:string => DIST_README_CONTENT, :to => "README.txt")
          end

          mkdir("lib") do
            render(:string => BASE_README_CONTENT, :to => "README.txt")
          end

          mkdir("recipes") do
            render(:string => RECIPE_README_CONTENT, :to => "README.txt")
          end
        end
        puts PNOTE+"DONE!"
      end # of interpreter.instance_eval
    end

    #---[ Default text content for generated files ]------------------------

    TAGS_CONTENT = <<-EOB # :nodoc:
# This is an AutomateIt tags file, used by AutomateIt::TagManager::YAML
#
# Use this file to assign tags to hosts using YAML. For example, to assign the
# tag "myrole" to two computers, named "host1" and "host2", you'd write:
#     myrole:
#       - host1
#       - host2
#
# In your recipes, you can then check if the host has these tags:
#     if tagged?("myrole")
#       # Do stuff if this host has the "myrole" tag
#     end
#
# You can also retrieve the tags:
#     puts "Tags for this host: \#{tags.inspect}"
#     # => ["myrole"]
#     puts "Tags for a specific host: \#{tags_for("host1").inspect}"
#     # => ["myrole"]
#     puts "Hosts tagged with a set of tags: \#{hosts_tagged_with("myrole").inspect}"
#     # => ["host1", "host2"]
#
# You may use ERB statements within this file.
#
#-----------------------------------------------------------------------

    EOB

    FIELDS_CONTENT = <<-EOB #:nodoc:
# This is an AutomateIt fields file, used by AutomateIt::FieldManager::YAML
#
# Use this file to create a multi-level hash of key value pairs with YAML. This
# is useful for extracting configuration-specific arguments out of your recipes
# and make it easier to share them between recipes and command-line UNIX
# programs.
#
# You can write lines like the following to declare these the hash with YAML:
#   foo: bar
#   mydaemon:
#     mykey: myvalue
#
# And then retrieve them in your recipe with:
#   lookup("foo") # => "bar"
#   lookup("mydaemon") # => {"mykey" => "myvalue"}
#   lookup("mydaemon#mykey") # => "myvalue"
#
# You may use ERB statements within this file. Because this file is loaded
# after the tags, you can use ERB to provide specific fields for specific
# groups of hosts, e.g.:
#
#   magical: <%#= tagged?("magical_hosts") ? true : false %>
#
#-----------------------------------------------------------------------

    EOB

    ENV_CONTENT = <<-EOB #:nodoc:
# This is an environment file for AutomateIt. It's loaded by the
# AutomateIt::Interpreter immediately after loading the default tags, fields
# and the contents of your "lib" directory. This file is loaded every time you
# invoke the AutomateIt interpreter with this project, so it's a good place to
# put your custom settings so that you can access them from recipes or an
# interpreter embedded inside your Ruby code.
#
# The "self" in this file is the AutomateIt::Interpreter, so you can execute
# all the same commands that you'd normally put in a recipe. However, note that
# because this file is executed each time the interpreter is loaded, you
# probably want to limit the commands added here to setup your interpreter the
# way you want it and add convenience methods, and not commands that do actual
# configuration management.
#
#-----------------------------------------------------------------------

    EOB

    BASE_README_CONTENT = <<-EOB #:nodoc:
# This is your AutomateIt project's "lib" directory. You can put custom plugins
# and convenience methods into this directory. For example, you'd put your
# custom PackageManager plugin here or a file that contains a method definition
# for a command you want to use frequently.
#
# These files are loaded every time an AutomateIt interpreter is created. It'll
# load all the "*.rb" files in this directory, and all the "init.rb" files in
# subdirectories within this directory. Because these files are loaded each
# time an interpreter is started, you should try to make sure these contents
# are loaded quickly and don't cause unintended side-effects.
    EOB

    DIST_README_CONTENT = <<-EOB #:nodoc:
# This is your AutomateIt project's "dist" directory. You should keep files and
# templates that you wish to distribute into this directory. You can access
# this path using the "dist" keyword in your recipes, for example:
#
#     # Render the template file "dist/foo.erb"
#     render(:file => dist+"/foo.erb", ...)
#
#     # Or copy the same file
#     cp(dist+"/foo.erb", ...)
    EOB

    RECIPE_README_CONTENT = <<-EOB #:nodoc:
# This is your AutomateIt project's "recipes" directory. You should put recipes
# into this directory. You can then execute them by running:
#
#     automateit your_project_path/recipes/your_recipe.rb
    EOB
  end
end
