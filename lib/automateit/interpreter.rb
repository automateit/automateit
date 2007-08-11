require 'automateit'

module AutomateIt
  class Interpreter < Common
    attr_accessor :parent

    def setup(opts={})
      super(opts.merge(:interpreter => self))

      if opts[:parent]
        @parent = opts[:parent]
      end

      if opts[:logger]
        @logger = opts[:logger]
      elsif not defined?(@logger) or @logger.nil?
          @logger = Logger.new(STDOUT)
          @logger.level = Logger::INFO
      end

      unless opts[:logger_level].nil?
        @logger.level = opts[:logger_level]
      end

      if opts[:noop].nil?
        @noop = false unless defined?(@noop)
      else
        @noop = opts[:noop]
      end

      instantiate_plugins
      expose_plugins
    end

    attr_accessor :plugins

    def instantiate_plugins
      @plugins ||= {}
      # XXX cleanup
      if defined?(@parent) and @parent and @parent.is_a?(Plugin::Manager)
        plugins[@parent.class.token] = @parent
      end
      AutomateIt::Plugin::Manager.classes.reject{|t| t == @parent if @parent}.each do |plugin_class|
        plugin_token = plugin_class.token

        if plugin = @plugins[plugin_token]
          plugin.instantiate_drivers
        else
          @plugins[plugin_token] = plugin_class.new(:interpreter => self,
                                                    :instantiating => true)
        end
      end
    end

    def expose_plugin_instances
      @plugins.each_pair do |token, plugin|
        unless methods.include?(token.to_s)
          self.class.send(:define_method, token) do
            @plugins[token]
          end
        end
      end
    end

    def expose_plugin_methods
      @plugins.values.each do |plugin|
        next unless plugin.class.aliased_methods
        plugin.class.aliased_methods.each do |method|
          unless methods.include?(method.to_s)
            self.class.send(:define_method, method) do |*args|
              @plugins[plugin.class.token].send(method, *args)
            end
          end
        end
      end
    end

    def expose_plugins
      expose_plugin_instances
      expose_plugin_methods
    end

    attr_writer :logger
    def logger(value=nil)
      if value.nil?
        return defined?(@logger) ? @logger : nil
      else
        @logger = value
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

    def eval(string=nil, &block)
      return string ? self.instance_eval(string) : self.instance_eval(&block)
    end
  end
end
