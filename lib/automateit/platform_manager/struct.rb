module AutomateIt
  class PlatformManager
    # == PlatformManager::Struct
    #
    # A simple PlatformManager driver that queries a hash for results. Although
    # not useful on its own, it's inherited by other drivers that provide
    # platform-specific methods to query the system.
    class Struct < Plugin::Driver
      # Hash mapping of keys that have many common names, e.g. "release" and "version"
      attr_accessor :key_aliases

      def available? # :nodoc:
        return true
      end

      def suitability(method, *args) # :nodoc:
        return 1
      end

      # Options:
      # * :struct - The hash to use for queries.
      def setup(opts={})
        super(opts)

        @@struct_cache ||= {}

        if opts[:struct]
          @struct = opts[:struct]
        else
          @struct ||= {}
        end

        # Generate bi-directional map
        @key_aliases ||= @@key_aliases ||= {
          :version => :release,
        }.inject({}){|s,v| s[v[0]] = v[1]; s[v[1]] = v[0]; s}
      end

      # See PlatformManager#query
      def query(search)
        result = ""
        for key in search.to_s.split(/#/)
          result << "_" unless result.empty?
          result << _query_key(key)
        end
        result
      end

      def _query_key(key)
        key = key.to_sym
        unless @struct.has_key?(key)
          key_alias = key_aliases[key]
          if @struct.has_key?(key_alias)
            key = key_alias
          else
            raise IndexError.new("platform doesn't provide key: #{key}")
          end
        end
        return @struct[key]
      end
      private :_query_key
    end
  end
end
