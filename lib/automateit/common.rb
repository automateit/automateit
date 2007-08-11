require 'automateit'

# XXX RDoc about AutomateIt
module AutomateIt #:main: AutomateIt

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

    def omfg(*args)
      "omfg"
    end
  end
end
