require 'automateit'

module AutomateIt
  class Interpreter < Common
    attr_accessor :parent

    def setup(opts={})
      super(opts.merge(:interpreter => self))

      if opts[:parent]
        @parent = opts[:parent]
      end

      if opts[:log]
        @log = opts[:log]
      elsif not defined?(@log) or @log.nil?
          @log = Logger.new(STDOUT)
          @log.level = Logger::INFO
      end

      if opts[:log_level] or opts[:verbosity]
        @log.level = opts[:log_level] || opts[:verbosity]
      end

      if opts[:noop].nil?
        @noop = false unless defined?(@noop)
      else
        @noop = opts[:noop]
      end

      # Instantiate core plugins so they're available to the project
      _instantiate_plugins

      if opts[:project]
        @project = opts[:project]
        log.debug("### Loading project from path: #{@project}")

        tag_file = File.join(@project, "config", "tags.yaml")
        if File.exists?(tag_file)
          log.debug("### Loading project tags: #{tag_file}")
          tag_manager[:yaml].setup(:file => tag_file)
        end

        field_file = File.join(@project, "config", "fields.yaml")
        if File.exists?(field_file)
          log.debug("### Loading project fields: #{field_file}")
          field_manager[:yaml].setup(:file => field_file)
        end

        lib_files = Dir[File.join(@project, "lib", "*.rb")] + Dir[File.join(@project, "lib", "**", "init.rb")]
        lib_files.each do |lib|
          log.debug("### Loading project library: #{lib}")
          invoke(lib)
        end

        # Instantiate project's plugins so they're available to the environment
        _instantiate_plugins

        env_file = File.join(@project, "config", "automateit_env.rb")
        if File.exists?(env_file)
          log.debug("### Loading project env: #{env_file}")
          invoke(env_file)
        end
      end
    end

    attr_accessor :project

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

    attr_writer :log
    def log(value=nil)
      if value.nil?
        return defined?(@log) ? @log : nil
      else
        @log = value
      end
    end

    attr_writer :noop
    def noop(value)
      @noop = value
    end

    def noop?(&block)
      if @noop and block
        block.call
      else
        @noop
      end
    end

    def writing(value)
      self.writing = value
    end

    def writing=(value)
      @noop = !value
    end

    def writing?(message=nil, &block)
      if block
        log.info("### #{message}") if message and @noop
        !@noop ? block.call : !@noop
      else
        !@noop
      end
    end

    def superuser?
      Process.euid.zero?
    end

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

    def invoke(recipe)
      # TODO lookup partial names
      data = File.read(recipe)
      eval data
    end
  end
end
