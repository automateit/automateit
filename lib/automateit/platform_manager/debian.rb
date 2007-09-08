# == PlatformManager::Debian
#
# A PlatformManager driver for Debian Linux.
class AutomateIt::PlatformManager::Debian < AutomateIt::PlatformManager::Uname
  VERSION_FILE = "/etc/debian_version"

  depends_on :files => [VERSION_FILE]

  def suitability(method, *args) # :nodoc:
    # Must be higher than PlatformManager::Struct
    return available? ? 3 : 0
  end

  def _prepare
    return if @struct[:distro]
    @struct[:distro] = "debian"
    @struct[:release] = File.read(VERSION_FILE).strip
    @struct
  end
  private :_prepare

  def query(search)
    _prepare
    super(search)
  end
end
