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
      def noop?() @interpreter.noop?() end

      # See Interpreter#writing=
      def writing=(value) @interpreter.writing=(value) end

      # See Interpreter#writing
      def writing(value) @interpreter.writing(value) end

      # See Interpreter#writing?
      def writing?() @interpreter.writing?() end

      # See Interpreter#preview?
      def preview?() @interpreter.preview?() end

      # See Interpreter#preview
      def preview(value=nil) @interpreter.preview(value) end

      # See Interpreter#preview=
      def preview=(value) @interpreter.preview=(value) end

      # See Interpreter#preview_for
      def preview_for(message, &block) @interpreter.preview_for(message, &block) end

      # See Interpreter#superuser?
      def superuser?() @interpreter.superuser? end
      
      # See Interpreter#nitpick
      def nitpick(value=nil) @interpreter.nitpick(value) end
    end
  end
end
