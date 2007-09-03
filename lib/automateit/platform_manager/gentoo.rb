module AutomateIt
  class PlatformManager
    # == PlatformManager::Gentoo
    #
    # A PlatformManager driver for Gentoo Linux.
    class Gentoo < Uname
      GENTOO_RELEASE = "/etc/gentoo-release"

      depends_on :files => [GENTOO_RELEASE]

      def suitability(method, *args) # :nodoc:
        # Must be higher than PlatformManager::Struct
        return available? ? 3 : 0
      end

      def _prepare
        return if @struct[:distro]
        @struct[:distro] = "gentoo"
        @struct[:release] = File.read(GENTOO_RELEASE).strip.match(/\s([\d\.]+)$/)[1]
        @struct
      end
      private :_prepare

      def query(search)
        _prepare
        super(search)
      end
    end
  end
end
