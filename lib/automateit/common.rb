module AutomateIt
  # == Common
  #
  # Common is the abstract class that most AutomateIt classes inherit from.
  class Common
    include AutomateIt::Constants

    # Interpreter instance for this class.
    attr_accessor :interpreter

    # Calls #setup with +options+ for processing.
    def initialize(options={})
      setup(options)
    end

    # Setup the class. Options:
    # * :interpreter - Set the Interpreter.
    def setup(options={})
      @interpreter = options[:interpreter] if options[:interpreter]
    end

    #---[ Interpreter aliases ]---------------------------------------------

    unless defined?(AutomateIt::Interpreter) and AutomateIt::Interpreter === self
      # See Interpreter#log
      def log() @interpreter.log end

      # See Interpreter#noop=
      def noop=(value) @interpreter.noop=(value) end

      # See Interpreter#noop
      def noop(value) @interpreter.noop(value) end

      # See Interpreter#noop?
      def noop?(&block) @interpreter.noop?(&block) end

      # See Interpreter#writing=
      def writing=(value) @interpreter.writing=(value) end

      # See Interpreter#writing
      def writing(value) @interpreter.writing(value) end

      # See Interpreter#writing?
      def writing?(message=nil, &block) @interpreter.writing?(message, &block) end

      # See Interpreter#superuser?
      def superuser?() @interpreter.superuser? end
    end
  end
end
