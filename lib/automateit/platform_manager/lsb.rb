module AutomateIt
  class PlatformManager
    # == PlatformManager::LSB
    #
    # A PlatformManager driver for LSB (Linux Standards Base) systems. The
    # platform doesn't actually need to be Linux, but simply has to provide an
    # <tt>lsb_release</tt> command.
    class LSB < Uname
      LSB_RELEASE = "lsb_release"

      depends_on :programs => [LSB_RELEASE]

      def suitability(method, *args) # :nodoc:
        # Level must be greater than Uname's
        return available? ? 3 : 0
      end

      def setup(opts={}) # :nodoc:
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
      private :_read_lsb_release_output
    end
  end
end
