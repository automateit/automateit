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

    def log
      @interpreter.log
    end

    def omfg(*args)
      "omfg"
    end
  end
end

# Lists methods unique to a class
class Object
  def unique_methods
    (public_methods - Object.methods).sort
  end
  def self.unique_methods
    (public_methods - Object.methods).sort
  end
end
