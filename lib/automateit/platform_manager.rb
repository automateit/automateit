require 'automateit'

module AutomateIt
  class PlatformManager < Plugin::Manager
    def query(search) dispatch(search) end

    #-----------------------------------------------------------------------

    class Struct < Plugin::Driver
      # Hash mapping of keys that have many common names, e.g. "release" and "version"
      attr_accessor :key_aliases

      def available?
        return true
      end

      def suitability(method, *args)
        return 1
      end

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

      def query(search)
        result = ""
        for key in search.to_s.split(/#/)
          result << "_" unless result.empty?
          result << query_key(key)
        end
        result
      end

      def query_key(key)
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
    end

    #-----------------------------------------------------------------------

    class Uname < Struct
      depends_on :programs => %w(uname)

      def suitability(method, *args)
        # Level must be greater than Struct's
        return available? ? 2 : 0
      end

      def setup(opts={})
        super(opts)
        @struct[:os]   ||= @@struct_cache[:os]   ||= `uname -s`.chomp.downcase
        @struct[:arch] ||= @@struct_cache[:arch] ||= `uname -m`.chomp.downcase
      end
    end

    #-----------------------------------------------------------------------

    class LSB < Uname
      LSB_RELEASE = "lsb_release"

      depends_on :programs => [LSB_RELEASE]

      def suitability(method, *args)
        # Level must be greater than Uname's
        return available? ? 3 : 0
      end

      def setup(opts={})
        super(opts) # Rely on Uname to set :os and :arch
        @struct[:distro]  ||= @@struct_cache[:distro]
        @struct[:release] ||= @@struct_cache[:release]
        unless @struct[:distro] and @struct[:release]
          # TODO Refactor using lazy-loading to boost performance.
          data = _read_lsb_release_output # SLOW 1.3s
          begin
            yaml = YAML::load(data)
            @struct[:distro]  ||= @@struct_cache[:distro]  ||= yaml["Distributor ID"].to_s.downcase
            @struct[:release] ||= @@struct_cache[:release] ||= yaml["Release"].to_s.downcase
          rescue NoMethodError, IndexError, ArgumentError => e
            raise ArgumentError.new("invalid YAML output from '#{LSB_RELEASE}': #{data.inspect}")
          end
        end
      end

      def _read_lsb_release_output
        # Discard STDERR because "lsb_release" spews warnings like "No LSB
        # modules are available." that we don't care about.
        return `"#{LSB_RELEASE}" -a 2>/dev/null`.gsub(/\t/, " ")
      end
    end
  end
end
