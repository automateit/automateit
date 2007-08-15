require 'automateit'

module AutomateIt
  class FieldManager < Plugin::Manager
    alias_methods :lookup

    def lookup(search) dispatch(search) end

    class Struct < Plugin::Driver
      def suitability(method, *args)
        return 1
      end

      def setup(opts={})
        super(opts)

        if opts[:struct]
          @struct = opts[:struct]
        else
          @struct = {}
        end
      end

      def lookup(search)
        ref = @struct
        for key in search.to_s.split("#")
          ref = ref[key]
        end
        ref
      end
    end

    require 'erb'
    require 'yaml'
    class YAML < Struct
      def suitability(method, *args)
        return 5
      end

      def setup(opts={})
        if filename = opts.delete(:file)
          opts[:struct] = ::YAML::load(::ERB.new(_read(filename), nil, '-').result)
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
