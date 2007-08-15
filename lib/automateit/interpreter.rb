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

      _instantiate_plugins
    end

    attr_accessor :plugins

    def _instantiate_plugins
      @plugins ||= {}
      # If a parent is defined, use it to prep the list and avoid re-instantiating it.
      if defined?(@parent) and @parent and @parent.is_a?(Plugin::Manager)
        @plugins[@parent.class.token] = @parent
      end
      plugin_classes = AutomateIt::Plugin::Manager.classes.reject{|t| t == @parent if @parent}.to_a
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
      if !@noop and block
        block.call
      else
        !@noop
      end
    end

    def superuser?
      Process.euid.zero?
    end
  end
end
