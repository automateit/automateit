module AutomateIt
  class TagManager
    # == TagManager::YAML
    #
    # A TagManager driver that reads tags from a YAML file.
    class YAML < Struct
      def available? # :nodoc:
        return true
      end

      def suitability(method, *args) # :nodoc:
        return 5
      end

      # Options:
      # * :file -- File to read tags from. The file is preprocessed with ERB and
      #   must produce YAML content.
      def setup(opts={})
        if filename = opts.delete(:file)
          opts[:struct] = ::YAML::load(ERB.new(_read(filename), nil, '-').result)
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
