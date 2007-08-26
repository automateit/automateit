require 'automateit'

module AutomateIt
  # == Interpreter
  #
  # The AutomateIt Interpreter is the class you'll use to create your
  # automation recipes.
  #
  # You can run a recipe from the command-line by running:
  #
  #   automateit your_recipe_file.rb
  #
  # Or start an interactive shell from the command-line by running:
  #
  #   automateit
  #
  # You can put commands into the recipe file or enter them into the
  # interpreter shell. You can enter any valid Ruby code, plus the special
  # methods offered by the interpreter. When you have enough code, you should
  # create a Project that contains your recipes and provides you with
  # additional convenience features, but you can read about that later.
  #
  # The best way to discover AutomateIt's methods is to start the interactive
  # shell and run commands from it. You can find out what commands the
  # interpreter offers by entering:
  #
  #   unique_methods
  #
  # This will display an array of strings, each one is the name of an
  # Interpreter method.  For example, there's a method called #superuser? that
  # tells you if you're running the interpreter with superuser (root)
  # privileges. You can run this by entering:
  #
  #   superuser?
  #
  # Most of your recipes will interact with plugins, these provide
  # functionality like installing software packages and creating users. You can
  # see what plugins are installed by entering:
  #
  #   plugins.keys
  #
  # The above command will return an array like:
  #
  #   [:field_manager, :shell_manager, :edit_manager, :address_manager,
  #   :account_manager, :package_manager, :tag_manager, :platform_manager,
  #   :template_manager, :service_manager]
  #
  # Each of these names represents a plugin. Remember when you ran the
  # <tt>unique_methods</tt> command earlier? You probably saw these managers
  # listed among the methods. Calling these managers will return an object you
  # can call methods on.
  #
  # For example, in the array we got above, we saw <tt>:shell_manager</tt>,
  # which corresponds to the ShellManager plugin. If you look at the
  # ShellManager documentation, you can see that it provides an +sh+ command
  # that executes shell commands. You can run this by entering:
  #
  #   shell_manager.sh "ls"
  #
  # You can also query the plugin object interactively by entering:
  #
  #   shell_manager.unique_methods
  #
  # You'll get an array of ShellManager's methods and see the #sh method
  # amongst them.
  #
  # For your convenience, the most common plugin methods are available by a
  # second, shorter name called an alias. For example, the
  # <tt>shell_manager.sh</tt> method is also available directly from the
  # interpreter as <tt>sh</tt>.
  #
  # A complete set of aliased methods includes:
  #
  # * cd => AutomateIt::ShellManager#cd
  # * chmod => AutomateIt::ShellManager#chmod
  # * chmod_R => AutomateIt::ShellManager#chmod_R
  # * chown => AutomateIt::ShellManager#chown
  # * chown_R => AutomateIt::ShellManager#chown_R
  # * chperm => AutomateIt::ShellManager#chperm
  # * cp => AutomateIt::ShellManager#cp
  # * cp_r => AutomateIt::ShellManager#cp_r
  # * edit => AutomateIt::EditManager#edit
  # * hosts_tagged_with => AutomateIt::TagManager#hosts_tagged_with
  # * install => AutomateIt::ShellManager#install
  # * ln => AutomateIt::ShellManager#ln
  # * ln_s => AutomateIt::ShellManager#ln_s
  # * ln_sf => AutomateIt::ShellManager#ln_sf
  # * lookup => AutomateIt::FieldManager#lookup
  # * mkdir => AutomateIt::ShellManager#mkdir
  # * mkdir_p => AutomateIt::ShellManager#mkdir_p
  # * mktemp => AutomateIt::ShellManager#mktemp
  # * mktempdir => AutomateIt::ShellManager#mktempdir
  # * mktempdircd => AutomateIt::ShellManager#mktempdircd
  # * mv => AutomateIt::ShellManager#mv
  # * pwd => AutomateIt::ShellManager#pwd
  # * render => AutomateIt::TemplateManager#render
  # * rm => AutomateIt::ShellManager#rm
  # * rm_r => AutomateIt::ShellManager#rm_r
  # * rm_rf => AutomateIt::ShellManager#rm_rf
  # * rmdir => AutomateIt::ShellManager#rmdir
  # * sh => AutomateIt::ShellManager#sh
  # * tagged? => AutomateIt::TagManager#tagged?
  # * tags => AutomateIt::TagManager#tags
  # * tags_for => AutomateIt::TagManager#tags_for
  # * touch => AutomateIt::ShellManager#touch
  # * umask => AutomateIt::ShellManager#umask
  # * which => AutomateIt::ShellManager#which
  # * which! => AutomateIt::ShellManager#which!
  #
  # Please read about the different methods available in the Interpreter and
  # the different plugins (e.g. ShellManager) to learn more about what you can
  # use AutomateIt for.
  #
  # You can also embed the AutomateIt interpreter inside an existing Ruby
  # program like this:
  #
  #   require 'automateit'
  #   interpreter = AutomateIt.new
  #
  #   # Use the interpreter as an object:
  #   interpreter.sh "ls -la" 
  #
  #   # Have it execute a recipe:
  #   interpreter.invoke "myrecipe.rb"
  #
  #   # Or execute recipes within a block
  #   interpreter.instance_eval do
  #     puts superuser?
  #     sh "ls -la"
  #   end
  #
  # Anyway, I hope you enjoy working with AutomateIt and look forward to
  # hearing about your experiences with it. Drivers, patches, documentation and
  # ideas are welcome. 
  #
  # --Igal Koshevoy
  class Interpreter < Common
    # Plugin instance that instantiated the Interpreter.
    attr_accessor :parent
    private :parent
    private :parent=

    # Project path for this Interpreter. If no path is available, nil.
    attr_accessor :project

    # Setup the Interpreter. This method is also called from Interpreter#new.
    #
    # Options for users:
    # * :verbosity - Alias for :log_level
    # * :log_level - Set log level, defaults to Logger::INFO.
    # * :noop - Set noop (no-operation) mode as boolean.
    # * :project - Set project as directory path.
    #
    # Options for internal use:
    # * :parent - Parent plugin instance.
    # * :log - QueuedLogger instance.
    def setup(opts={})
      super(opts.merge(:interpreter => self))

      if opts[:parent]
        @parent = opts[:parent]
      end

      if opts[:log]
        @log = opts[:log]
      elsif not defined?(@log) or @log.nil?
        @log = QueuedLogger.new($stdout)
        @log.level = Logger::INFO
      end

      if opts[:log_level] or opts[:verbosity]
        @log.level = opts[:log_level] || opts[:verbosity]
      end

      if opts[:noop].nil? # can be false
        @noop = false unless defined?(@noop)
      else
        @noop = opts[:noop]
      end

      # Instantiate core plugins so they're available to the project
      _instantiate_plugins

      if project_path = opts[:project] || ENV["AUTOMATEIT_PROJECT"]
        # Only load a project if we find its env file
        env_file = File.join(project_path, "config", "automateit_env.rb")
        if File.exists?(env_file)
          @project = File.expand_path(project_path)
          log.debug(PNOTE+"Loading project from path: #{@project}")

          tag_file = File.join(@project, "config", "tags.yml")
          if File.exists?(tag_file)
            log.debug(PNOTE+"Loading project tags: #{tag_file}")
            tag_manager[:yaml].setup(:file => tag_file)
          end

          field_file = File.join(@project, "config", "fields.yml")
          if File.exists?(field_file)
            log.debug(PNOTE+"Loading project fields: #{field_file}")
            field_manager[:yaml].setup(:file => field_file)
          end

          lib_files = Dir[File.join(@project, "lib", "*.rb")] + Dir[File.join(@project, "lib", "**", "init.rb")]
          lib_files.each do |lib|
            log.debug(PNOTE+"Loading project library: #{lib}")
            invoke(lib)
          end

          # Instantiate project's plugins so they're available to the environment
          _instantiate_plugins

          if File.exists?(env_file)
            log.debug(PNOTE+"Loading project env: #{env_file}")
            invoke(env_file)
          end
        end
      end
    end

    # Hash of plugin tokens to plugin instances for this Interpreter.
    attr_accessor :plugins

    def _instantiate_plugins
      @plugins ||= {}
      # If a parent is defined, use it to prep the list and avoid re-instantiating it.
      if defined?(@parent) and @parent and Plugin::Manager === @parent
        @plugins[@parent.class.token] = @parent
      end
      plugin_classes = AutomateIt::Plugin::Manager.classes.reject{|t| t == @parent if @parent}
      for klass in plugin_classes
        _instantiate_plugin(klass)
      end
    end
    private :_instantiate_plugins

    def _instantiate_plugin(klass)
      token = klass.token
      return if @plugins[token]
      plugin = @plugins[token] = klass.new(:interpreter => self)
      #puts "!!! ip #{token}"
      unless respond_to?(token.to_sym)
        self.class.send(:define_method, token) do
          @plugins[token]
        end
      end
      _expose_plugin_methods(plugin)
    end
    private :_instantiate_plugin

    def _expose_plugin_methods(plugin)
      return unless plugin.class.aliased_methods
      plugin.class.aliased_methods.each do |method|
        #puts "!!! epm #{method}"
        unless respond_to?(method.to_sym)
          # Must use instance_eval because methods created with define_method
          # can't accept block as argument. This is a known Ruby 1.8 bug.
          self.instance_eval <<-EOB
            def #{method}(*args, &block)
              @plugins[:#{plugin.class.token}].send(:#{method}, *args, &block)
            end
          EOB
        end
      end
    end
    private :_expose_plugin_methods

    # Set the QueuedLogger instance for the Interpreter.
    attr_writer :log

    # Get or set the QueuedLogger instance for the Interpreter, a special
    # wrapper around the Ruby Logger.
    def log(value=nil)
      if value.nil?
        return defined?(@log) ? @log : nil
      else
        @log = value
      end
    end

    # Set noop (no-operation mode) to +value+.
    def noop(value)
      self.noop = value
    end

    # Set noop (no-operation mode) to +value+.
    def noop=(value)
      @noop = value
    end

    # Are we in noop (no-operation) mode? If a block is given, executes the
    # block if in noop mode.
    def noop?(&block)
      if @noop and block
        block.call
      else
        @noop
      end
    end

    # Set writing to +value+.
    def writing(value)
      self.writing = value
    end

    # Set writing to +value+.
    def writing=(value)
      @noop = !value
    end

    # Are we writing? Opposite of #noop. If given a block, executes it when in
    # writing mode. If given a +message+, displays it when in noop mode, which
    # is handy so you can preview a complex command.
    #
    # Example:
    #   writing?("Making big changes") do
    #     # do your big changes
    #     sh "ls -la"
    #   end
    #
    #   # When in noop mode, will print the message and won't execute the block:
    #   => Making big changes
    #
    #   # When in writing mode, won't print the message and will execute the block:
    #   ** ls -la
    def writing?(message=nil, &block)
      if block
        log.info(PNOTE+"#{message}") if message and @noop
        !@noop ? block.call : !@noop
      else
        !@noop
      end
    end

    # Does the current user have superuser (root) privileges?
    def superuser?
      Process.euid.zero?
    end

=begin
    def run_nonblocking(command, callback)
      data = ""
      IO.popen(command) do |handle|
        begin
          while true
            sleep 0.1
            latest = handle.readpartial(4048)
            data << latest
            callback.call(latest)
          end
        rescue EOFError
          # Expected error that indicates there's nothing to read
        end
      end
      return data
    end
=end

    # Invoke the +recipe+ at the given path.
    def invoke(recipe)
      # FIXME doing eval breaks the exception backtraces
      # TODO lookup partial names
      data = File.read(recipe)
      eval(data, binding, recipe, 0)
    end

    # Path of this project's "dist" directory. If a project isn't available or
    # the directory doesn't exist, this will throw a NotImplementedError.
    def dist
      if @project
        result = File.join(@project, "dist")
        if File.directory?(result)
          return result
        else
          raise NotImplementedError.new("can't find dist directory at: #{result}")
        end
      else
        raise NotImplementedError.new("can't use dist without a project")
      end
    end
  end
end
