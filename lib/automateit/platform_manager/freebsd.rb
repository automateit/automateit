# == PlatformManager::FreeBSD
#
# A PlatformManager driver for FreeBSD.
class AutomateIt::PlatformManager::FreeBSD < AutomateIt::PlatformManager::Uname
  def self.token
    :freebsd
  end

  depends_on :files => %w(/etc/portsnap.conf /etc/rc.conf)

  def suitability(method, *args) # :nodoc:
    # Must be higher than PlatformManager::Struct
    return available? ? 3 : 0
  end

  def _prepare
    return if @struct[:distro]
    @struct[:distro] = "freebsd"
    @struct[:release] = `uname -r`.strip.match(/^([\d\.]+)-/)[1]
    @struct
  end
  private :_prepare

  def query(search)
    _prepare
    super(search)
  end
end

