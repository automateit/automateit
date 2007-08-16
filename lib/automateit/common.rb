require 'automateit'

# XXX RDoc about AutomateIt
module AutomateIt #:main: AutomateIt

  VERSION=0.0

  # Instantiate an +Interpreter+.
  def self.new(*a)
    Interpreter.new(*a)
  end

  class Common
    attr_accessor :interpreter

    def initialize(opts={})
      setup(opts)
    end

    def setup(opts={})
      @interpreter = opts[:interpreter] if opts[:interpreter]
    end

    def omfg(*args) "omfg" end

    #---[ Interpreter aliases ]---------------------------------------------

    unless defined?(AutomateIt::Interpreter) and AutomateIt::Interpreter === self
      def log() @interpreter.log end

      def noop=(value) @interpreter.noop=(value) end
      def noop(value) @interpreter.noop(value) end
      def noop?(&block) @interpreter.noop?(&block) end
      
      def writing=(value) @interpreter.writing=(value) end
      def writing(value) @interpreter.writing(value) end
      def writing?(message=nil, &block) @interpreter.writing?(message, &block) end

      def superuser?() @interpreter.superuser? end
    end
  end
end

class Object
  # Lists methods unique to an instance.
  def unique_methods
    (public_methods - Object.methods).sort
  end

  # Lists methods unique to a class.
  def self.unique_methods
    (public_methods - Object.methods).sort
  end

  # Returns a list of arguments and an options hash. Source taken from RSpec.
  def args_and_opts(*args)
    options = Hash === args.last ? args.pop : {}
    return args, options
  end
end
