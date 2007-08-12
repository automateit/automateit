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

    class Uname < Struct
      def suitability(method, *args)
        return @suitable ||= (interpreter.which("uname").nil? ? 0 : 1)
      end

      def setup(opts={})
        super(opts)
        @@struct_cache ||= {}
        @struct[:os] ||= @@struct_cache[:os] ||= `uname -s`.chomp.downcase
        @struct[:arch] ||= @@struct_cache[:arch] ||= `uname -m`.chomp.downcase
      end
    end

    class LSB < Uname
      def suitability(method, *args)
        return @suitable ||= (interpreter.which("lsb_release").nil? ? 0 : 2)
      end

      def setup(opts={})
        super(opts)
        @struct[:distro] ||= @@struct_cache[:distro]
        @struct[:release] ||= @@struct_cache[:release]
        unless @struct[:distro] and @struct[:release]
          Open3.popen3("lsb_release", "-a") do |sin, sout, serr|
            next if (rawdata = sout.read).empty?
            yamldata = YAML::load(rawdata.gsub(/\t/, " "))
            @struct[:distro] = @@struct_cache[:distro] = yamldata["Distributor ID"].to_s.downcase
            @struct[:release] = @@struct_cache[:release] = yamldata["Release"].to_s.downcase
          end
        end
      end
    end
  end
end
