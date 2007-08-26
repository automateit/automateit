module AutomateIt
  # == FieldManager
  #
  # The FieldManager provides a way of accessing a hash of constants that
  # represent configuration data. These are typically stored in a project's
  # <tt>config/fields.yml</tt> file.
  #
  # For example, consider a <tt>field.yml</tt> that contains YAML like:
  #   foo: bar
  #   my_app:
  #     my_key: my_value
  #
  # With the above file, we can query the fields like this:
  #   lookup(:foo) # => "bar"
  #   lookup("foo") # => "bar"
  #   lookup("my_app#my_key") # => "my_value"
  #   lookup("my_app#my_branch") # => "my_value"
  class FieldManager < Plugin::Manager
    alias_methods :lookup

    def lookup(search) dispatch(search) end

    #-----------------------------------------------------------------------

    # == FieldManager::Struct
    #
    # A FileManager driver that queries a data structure.
    class Struct < Plugin::Driver
      def available? # :nodoc:
        return true
      end

      def suitability(method, *args) # :nodoc:
        return 1
      end

      # Options:
      # * :struct -- Hash to use as the fields data structure.
      def setup(opts={})
        super(opts)

        if opts[:struct]
          @struct = opts[:struct]
        else
          @struct = {}
        end
      end

      # See FieldManager#lookup
      def lookup(search)
        ref = @struct
        for key in search.to_s.split("#")
          ref = ref[key]
        end
        ref
      end
    end

    #-----------------------------------------------------------------------

    # == FieldManager::YAML
    #
    # A FieldManager driver that reads its data structure from a file.
    class YAML < Struct
      def available? # :nodoc:
        return true
      end

      def suitability(method, *args) # :nodoc:
        return 5
      end

      # Options:
      # * :file -- Filename to read data structure from. Contents will be
      #   parsed with ERB and then handed to YAML.
      def setup(opts={})
        if filename = opts.delete(:file)
          opts[:struct] = ::YAML::load(
            ::ERB.new(_read(filename), nil, '-') \
            .result(interpreter.send(:binding)))
        end
        super(opts)
      end

      def _read(filename)
        return File.read(filename)
      end
      private :_read
    end
  end
end
