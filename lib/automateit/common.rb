require 'automateit'

# XXX RDoc about AutomateIt
module AutomateIt #:main: AutomateIt

  VERSION=0.0

  # Instantiate an +Interpreter+.
  def self.new(*options)
    Interpreter.new(*options)
  end

  class Common
    attr_accessor :interpreter

    def initialize(options={})
      setup(options)
    end

    def setup(options={})
      @interpreter = options[:interpreter] if options[:interpreter]
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

      def cache() @interpreter.cache end
    end
  end
end

# TODO move to 'extensions/object.rb'
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
