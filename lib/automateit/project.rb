module AutomateIt
  # = Project
  #
  # An AutomateIt Project is a collection of related recipes, tags, fields and
  # custom plugins.
  #
  # === Create a project
  #
  # You can create a project by running the following from the Unix shell:
  #
  #   automateit --create myproject
  #
  # This will create a directory called +myproject+ with a number of
  # directories and files. Each directory has a <tt>README.txt</tt> that
  # explains what it's used for.
  #
  # === Advantages of a project over raw recipe files
  #
  # Although you can run recipes without a project, putting your recipes into a
  # project provides you with the following benefits:
  #
  # 1. Directory structure to organize your files.
  # 2. Automatically loads tags from project's <tt>config/tags.yml</tt> file.
  # 3. Loads fields from the <tt>config/fields.yml</tt> file.
  # 4. Loads all custom plugins and libraries found in the +lib+ directory.
  # 5. Provides a +dist+ method that corresponds to your project's +dist+
  #   directory. Using this method will save you from having to type paths for
  #   files you intend to distribute from recipes, e.g.:
  #     cp(dist+"/source.txt", "/tmp/target.txt")
  #
  # === Using a project
  #
  # For example, create a new project:
  #
  #   automateit --create hello_project
  #
  # Inside this project, edit its fields, which are stored in the
  # <tt>config/fields.yml</tt> file, and make it look like this:
  #
  #   greeting: Hello world!
  #
  # Then create a recipe in the <tt>recipes/greet.rb</tt> file:
  #
  #   puts lookup(:greeting)
  #
  # You can run the recipe:
  #
  #   automateit recipes/greet.rb
  #
  # And you should get the following output:
  #
  #   Hello world!
  #
  # === Using project libraries
  #
  # Any files ending with <tt>.rb</tt> that you put into the project's
  # <tt>lib</tt> directory will be loaded before your recipe starts executing.
  # This is a good way to add common features, custom plugins and such.
  #
  # For example, put the following into a new <tt>lib/meow.rb</tt> file:
  #
  #   def meow
  #     "MEOW!"
  #   end
  #
  # Now create a new recipe that uses this nethod in <tt>recipes/speak.rb</tt>
  #
  #   puts meow
  #
  # Now you can run it:
  #
  #   automateit recipes/speak.rb
  #
  # And you'll get this:
  #
  #   MEOW!
  #
  # === Specifying project paths on the Unix shell
  #
  # AutomateIt will load the project automatically if you're executing a recipe
  # that's inside a project's +recipes+ directory.
  #
  # For example, assume that you've create your project as
  # <tt>/tmp/hello_project</tt> and have a recipe at
  # <tt>/tmp/hello_project/recipes/greet.rb</tt>.
  #
  # You can execute the recipe with a full path:
  #
  #   automateit /tmp/hello_project/recipes/greet.rb
  #
  # Or execute it with a relative path:
  #
  #   cd /tmp/hello_project/recipes
  #   automateit greet.rb
  #
  # Or you can prepend a header to the <tt>greet.rb</tt> recipe so it looks like this
  #
  #   #!/usr/bin/env automateit
  #
  #   puts lookup(:greeting)
  #
  # And then make the file executable:
  #
  #   chmod a+X /tmp/hello_project/recipes/greet.rb
  #
  # And execute the recipe directly:
  #
  #   /tmp/hello_project/recipes/greet.rb
  #
  # === Specifying project paths for embedded programs
  #
  # If you're embedding the Interpreter into another Ruby program, you can run recipes and they'll automatically load the project if applicable. For example:
  #
  #   require 'rubygems'
  #   require 'automateit'
  #   AutomateIt.invoke("/tmp/hello_project/recipes/greet.rb")
  #
  # Or if you may specify the project path explicitly:
  #
  #   require 'rubygems'
  #   require 'automateit'
  #   interpreter = AutomateIt.new(:project => "/tmp/hello_project")
  #   puts interpreter.lookup("greeting")
  #
  # === Tag and field command-line helpers
  #
  # You can access a project's tags and fields from the Unix shell. This
  # helps other programs access configuration data and make use of your roles.
  #
  # For example, with the <tt>hello_project</tt> we've created, we can lookup
  # fields from the Unix shell like this:
  #
  #   aifield -p /tmp/hello_project greeting
  #
  # The <tt>-p</tt> specifies the project path (its an alias for
  # <tt>--project</tt>). More commands are available. You can see the
  # documentation and examples for these commands by running:
  #
  #   aifield --help
  #   aitag --help
  #
  # Sometimes it's convenient to set a default project path so you don't need
  # to type as much by specifing the <tt>AUTOMATEIT_PROJECT</tt> environmental
  # variable (or <tt>AIP</tt> if you want a shortcut) and use it like this:
  #
  #   export AUTOMATEIT_PROJECT=/tmp/hello_project
  #   aifield greeting
  #
  # === Sharing a project between systems
  #
  # If you want to share a project between different hosts, you're responsible for distributing the files between them. This isn't a big deal though because these are just text files and your OS has dozens of excellent ways to distribute these.
  #
  # Common approaches to distribution:
  # * *Shared directory*: Your hosts mount a shared network directory (e.g., +nfs+ or +smb+) with your project. This is very easy if your hosts already have a shared directory, but can be a nuisance otherwise because it opens potential security holes and risks having you hosts hang if the master goes offline.
  # * *Client pull*: Your hosts download the latest copy of your project from a master repository using a remote copy tool (e.g., +rsync+) or a revision control system (e.g., +cvs+, +svn+, +hg+). This is a safe, simple and secure option.
  # * *Server push*: You have a master push out the project files to clients using a remote copy tool. This can be awkward and time-consuming because the server must go through a list of all hosts and copy files to them individually.
  #
  # An example of a complete solution for distributing system configuration management files:
  # * Setup an +svn+ or +hg+ repository to store your project and create a special account for the hosts to use to checkout code.
  # * Write a wrapper script for running the recipes, for example, write a "/usr/bin/myautomateit" shell script like:
  #
  #     #!/bin/sh
  #     cd /var/local/myautomateit
  #     svn update --quiet
  #     automateit recipe/default.rb
  # * Run this wrapper once an hour using cron so that your systems are always up to date. AutomateIt only prints output when it makes a change, so cron will only email you when you commit new code to the repository and the hosts make changes.
  # * If you need to run a recipe on the machine right now, SSH into it and run the wrapper.
  # * If you need to run the script early on a bunch of machines and don't want to manually SSH into each one, you can leverage the +aitag+ (see <tt>aitag --help</tt>) to execute a Unix command across multiple systems. For example, you could use a Unix shell command like this to execute the wrapper on all hosts tagged with +apache_servers+:
  #
  #     for host in `aitag -p /var/local/myautomateit -w apache_server`; do
  #         echo "# $host"
  #         ssh $host myautomateit
  #     done
  #
  # === Curios
  #
  # In case you're interested, the project creator is actually an AutomateIt
  # recipe. You can read the recipe source code by looking at the
  # AutomateIt::Project::create method.
  class Project < Common
    # Create a new project.
    #
    # Options:
    # * :create -- Project path to create. Required.
    # * All other options are passed to the AutomateIt::Interpreter.
    def self.create(opts)
      display = lambda {|message| puts message if ! opts[:verbosity] || (opts[:verbosity] && opts[:verbosity] <= Logger::INFO) }

      path = opts.delete(:create) \
        or raise ArgumentError.new(":create option not specified")
      interpreter = AutomateIt.new(opts)
      interpreter.instance_eval do
        # Make +render+ only generate files only if they don't already exist.
        template_manager.default_check = :exists

        mkdir_p(path) do |created|
          if created
            display.call PNOTE+"Creating AutomateIt project at: #{path}"
          else
            display.call PNOTE+"Found AutomateIt project at: #{path}"
          end

          mkdir("config") do
            render(:text => TAGS_CONTENT, :to => "tags.yml")
            render(:text => FIELDS_CONTENT, :to => "fields.yml")
            render(:text => ENV_CONTENT, :to => "automateit_env.rb")
          end

          mkdir("dist") do
            render(:text => DIST_README_CONTENT, :to => "README.txt")
          end

          mkdir("lib") do
            render(:text => BASE_README_CONTENT, :to => "README.txt")
          end

          mkdir("recipes") do
            render(:text => RECIPE_README_CONTENT, :to => "README.txt")
          end
        end
        display.call PNOTE+"DONE!"
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
# and make it easier to share them between recipes and command-line Unix
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
