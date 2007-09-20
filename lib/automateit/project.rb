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
  # Now create a new recipe that uses this method in <tt>recipes/speak.rb</tt>
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
        # +render+ only files that don't exist.
        template_manager.default_check = :exists

        mkdir_p(path) do |created|
          display.call PNOTE+"%s AutomateIt project at: %s" %
            [created ? "Creating" : "Updating", path]

          render(:text => WELCOME_CONTENT, :to => "README_AutomateIt.txt")
          render(:text => RAKEFILE_CONTENT, :to => "Rakefile")

          mkdir("config")
          render(:text => TAGS_CONTENT, :to => "config/tags.yml")
          render(:text => FIELDS_CONTENT, :to => "config/fields.yml")
          render(:text => ENV_CONTENT, :to => "config/automateit_env.rb")

          mkdir("dist")
          render(:text => DIST_README_CONTENT, :to => "dist/README_AutomateIt_dist.txt")

          mkdir("lib")
          render(:text => BASE_README_CONTENT, :to => "lib/README_AutomateIt_lib.txt")

          mkdir("recipes")
          render(:text => RECIPE_README_CONTENT, :to => "recipes/README_AutomateIt_recipes.txt")
          render(:text => RECIPE_HELLO_CONTENT, :to => "recipes/hello.rb")
        end

        if log.info? and not opts[:quiet]
          puts '-----------------------------------------------------------------------'
          puts WELCOME_MESSAGE
          puts '-----------------------------------------------------------------------'
        end
      end # of interpreter.instance_eval
    end

    #---[ Default text content for generated files ]------------------------

    WELCOME_MESSAGE = <<-EOB #:nodoc:
Welcome to AutomateIt!

Learn:
* See it in action at http://AutomateIt.org/screenshots
* Read the tutorial at http://AutomateIt.org/tutorial
* Read the documentation at http://AutomateIt.org/documentation
* See the README files created in the project

Run:
* `automateit -p .` -- Starts interactive shell for project
* `automateit recipes/hello.rb` -- Runs a recipe called recipes/hello.rb
* `automateit -n recipes/hello.rb` -- Previews recipe

Rake:
* `rake` -- Starts interactive shell for project
* `rake hello` -- Runs sample recipe
* `rake preview` -- Turns on preview mode
* `rake preview hello` -- Previews the sample recipe

Changes:
* Sign up for RSS feed at http://automateit.org/changes
EOB

    welcome_lines = WELCOME_MESSAGE.split(/\n/)
    welcome_title = welcome_lines.first
    welcome_body = welcome_lines[2, welcome_lines.size]
    WELCOME_CONTENT = <<-EOB #:nodoc:
#-----------------------------------------------------------------------
#
# == #{welcome_title}
#
#{welcome_body.map{|t| "# %s" % t}.join("\n")}
#
#-----------------------------------------------------------------------
EOB

    TAGS_CONTENT = <<-EOB # :nodoc:
# Put your roles here

#-----------------------------------------------------------------------
#
# == TAGS
#
# This is an AutomateIt tags file. Use it to assign tags to hosts so you
# can manage multiple hosts as a group.
#
# For example, in this file assign the tag "myrole" to two computers
# named "host1" and "host2":
#
#     myrole:
#       - host1
#       - host2
#
# Then check from a recipe if this host has this tag:
#
#     if tagged?("myrole")
#       # Code will only run if this host is tagged with "myrole"
#     end
#
# You can also retrieve tags:
#
#     puts "Tags for this host: \#{tags.inspect}"
#     # => ["myrole"]
#     puts "Tags for a specific host: \#{tags_for("host1").inspect}"
#     # => ["myrole"]
#     puts "Hosts with a tag: \#{hosts_tagged_with("myrole").inspect}"
#     # => ["host1", "host2"]
#
# You will likely see additional tags which are automatically added
# based on the host's operating system, architecture, hostnames, etc.
#
# You may use ERB statements within this file.
#
# See AutomateIt::TagManager for further details.
#
#-----------------------------------------------------------------------
    EOB

    FIELDS_CONTENT = <<-EOB #:nodoc:
# Put your fields here

#-----------------------------------------------------------------------
#
# == FIELDS
#
# This is an AutomateIt fields file. Fields are useful for extracting
# configuration-specific arguments out of your recipe logic, and making
# them easier to share between recipes and access from other programs.
#
# For example, declare fields using YAML:
#
#   foo: bar
#   mydaemon:
#     mykey: myvalue
#
# And retrieve field values from a recipe:
#
#   lookup("foo") # => "bar"
#   lookup("mydaemon") # => {"mykey" => "myvalue"}
#   lookup("mydaemon#mykey") # => "myvalue"
#
# You may use ERB statements within this file. Because this file is
# loaded after the tags, you can use ERB to dynamically set fields for
# specific groups of hosts, e.g.:
#
#   magical: <%%= tagged?("magical_hosts") ? true : false %>
#
# See AutomateIt::FieldManager for further details.
#
#-----------------------------------------------------------------------
    EOB

    ENV_CONTENT = <<-EOB #:nodoc:
# Put your environment commands here

#-----------------------------------------------------------------------
#
# == ENVIRONMENT
#
# This is an AutomateIt environment file. Use it to customize AutomateIt
# and provide settings to recipes, interactive shell, or embedded
# Interpreters using this project.
#
# The "self" in this file is an Interpreter instance, so you can execute
# all the same commands that you'd normally put in a recipe.
#
# This file is loaded after the project's tags, fields and libraries.
#
#-----------------------------------------------------------------------
    EOB

    BASE_README_CONTENT = <<-EOB #:nodoc:
#-----------------------------------------------------------------------
#
# == LIB
#
# This is your AutomateIt project's "lib" directory. You can put custom
# plugins and convenience methods into this directory.
#
# For example, create a convenience method for geteting the time by
# creating a "lib/now.rb" file with the following contents:
#
#   def now
#     DateTime.now
#   end
#
# This will provide a "now" method that's available to your recipes,
# interactive shell or embedded interpreter.
#
# Libraries are loaded every time an AutomateIt interpreter is started.
# It loads all "*.rb" files in this directory, and all "init.rb" files
# in subdirectories of this directory.
#
#-----------------------------------------------------------------------
    EOB

    DIST_README_CONTENT = <<-EOB #:nodoc:
#-----------------------------------------------------------------------
#
# == DIST
#
# This is your AutomateIt project's "dist" directory. It's a place for
# keeping files and templates you plan to distribute.
#
# You can retrieve this directory's path using the "dist" method in
# recipes, for example:
#
#     # Display the "dist" directory's path
#     puts dist
#
#     # Render the template file "dist/foo.erb"
#     render(:file => dist+"/foo.erb", ...)
#
#     # Or copy the same file somewhere
#     cp(dist+"/foo.erb", ...)
#
#-----------------------------------------------------------------------
    EOB

    RECIPE_README_CONTENT = <<-EOB #:nodoc:
#-----------------------------------------------------------------------
#
# == RECIPES
#
# This is your AutomateIt project's "recipes" directory. You should put
# recipes into this directory.
#
# For example, create a "recipes/hello.rb" file with these contents:
#
#   puts "Hello"
#
# And execute it with:
#
#     automateit recipes/your_recipe.rb
#
#-----------------------------------------------------------------------
    EOB

    RECIPE_HELLO_CONTENT = <<-'EOB' #:nodoc
puts "Hello, I'm an #{self.class} -- pleased to meet you!"
puts "I'm in preview mode" if preview?
    EOB

    RAKEFILE_CONTENT = <<-EOB #:nodoc
require "automateit"

# Create an Interpreter for project in current directory.
@interpreter = AutomateIt.new(:project => ".")

# Include Interpreter's methods into Rake session.
@interpreter.include_in(self)

task :default => :shell

desc "Interactive AutomateIt shell"
task :shell do
  AutomateIt::CLI.run
end

desc "Run a recipe"
task :hello do
  invoke "hello"
end

desc "Preview action, e.g, 'rake preview hello'"
task :preview do
  preview true
end
    EOB
  end
end
