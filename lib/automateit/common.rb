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
    self.class.unique_methods
  end
  def self.unique_methods
    (self.methods - Object.methods).sort
  end
end
