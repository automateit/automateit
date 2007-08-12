require 'automateit'

module AutomateIt
  class PlatformManager < Plugin::Manager
    def query(search) dispatch(search) end

    require 'stringio'
    class Struct < Plugin::Driver
      # Hash mapping of keys that have many common names, e.g. "relase" and "version"
      attr_accessor :key_aliases

      def suitability(method, *args)
        return 1
      end

      def setup(opts={})
        super(opts)

        if opts[:struct]
          @struct = opts[:struct]
        else
          @struct ||= {}
        end

        # Generate bi-directional map
        @key_aliases ||= {
          :version => :release,
        }.inject({}){|s,v| s[v[0]] = v[1]; s[v[1]] = v[0]; s}
      end

      def query(search)
        result = ""
        for key in search.to_s.split(/#/)
          key = key.to_sym
          result << "_" unless result.empty?
          unless @struct.has_key?(key)
            key_alias = key_aliases[key]
            if @struct.has_key?(key_alias)
              key = key_alias
            else
              raise IndexError.new("platform doesn't provide key: #{key}")
            end
          end
          result << @struct[key]
        end
        result
      end
    end

    class LSB < Struct
      def suitability(method, *args)
        # Don't accept queries if +populate+ couldn't put data into @struct.
        return @struct.empty? ? -1 : 5
      end

      def setup(opts={})
        super(opts)
        populate
      end

      def populate
        return unless @struct.empty?
        unless defined?(@@struct_cache) and @@struct_cache
          @@struct_cache = {}
          Open3.popen3("lsb_release", "-a") do |sin, sout, serr|
            next if (rawdata = sout.read).empty?
            yamldata = YAML::load(rawdata.gsub(/\t/, " "))
            @@struct_cache[:distro] = yamldata["Distributor ID"].to_s.downcase
            @@struct_cache[:release] = yamldata["Release"].to_s.downcase

            @@struct_cache[:os] = `uname -s`.chomp.downcase
            @@struct_cache[:arch] = `uname -m`.chomp.downcase
          end
        end
        @struct = @@struct_cache
      end
    end
  end
end
