require "rubygems"
require "active_support"
require "automateit"

module AutomateIt
  class CLI
    def initialize(opts={})
      opts[:project] ||= opts[:recipe] ? File.join(File.dirname(opts[:recipe]), "..") : "."
      if opts[:create]
        self.class.create_project(opts)
      elsif opts[:recipe]
        interpreter = AutomateIt.new(opts)
        interpreter.invoke(recipe)
      elsif code = opts.delete(:eval)
        interpreter = AutomateIt.new(opts)
        interpreter.instance_eval(code)
      else
        require "irb"
        unless opts[:quiet]
          puts "### AutomateIt Shell v#{AutomateIt::VERSION}"
          puts "### <CTRL-D> to quit, <Tab> to auto-complete"
        end
        IRB.setup(__FILE__)
        irb = IRB::Irb.new
        IRB.instance_variable_get(:@CONF)[:MAIN_CONTEXT] = irb.context
        interpreter = AutomateIt.new(opts)
        irb.context.workspace.instance_variable_set(:@binding, interpreter.send(:binding))
        irb.eval_input
      end
    end

    def self.create_project(opts)
        path = opts.delete(:create)
        interpreter = AutomateIt.new(opts)
        interpreter.instance_eval do
          if mkdir_p(path)
            puts "### Creating AutomateIt project at: #{path}"
          else
            puts "### Updating AutomateIt project at: #{path}"
          end
          mkdir(path+"/config")

          render(:string => <<-EOB, :to => path+"/config/tags.yml", :check => :exists)
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

          render(:string => <<-EOB, :to => path+"/config/fields.yml", :check => :exists)
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

          render(:string => <<-EOB, :to => path+"/config/automateit_env.rb", :check => :exists)
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

          mkdir(path+"/lib")
          render(:string => <<-EOB, :to => path+"/lib/README.txt", :check => :exists)
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

          mkdir(path+"/recipes")
          render(:string => <<-EOB, :to => path+"/recipes/README.txt", :check => :exists)
# This is your AutomateIt project's "recipes" directory. You should put recipes
# into this directory. You can then execute them by running:
#     automateit your_project_path/recipes/your_recipe.rb
          EOB
        end # of interpreter.instance_eval
        puts "### DONE!"
    end
  end
end
