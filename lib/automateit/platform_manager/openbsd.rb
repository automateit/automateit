# == PlatformManager::OpenBSD
#
# A PlatformManager driver for OpenBSD.
class AutomateIt::PlatformManager::OpenBSD < AutomateIt::PlatformManager::Uname
  def self.token
    :openbsd
  end

  depends_on :files => %w(/obsd /bsd /bsd.rd), :directories => %w(/altroot /stand)

  def suitability(method, *args) # :nodoc:
    # Must be higher than PlatformManager::Struct
    return available? ? 3 : 0
  end

  def _prepare
    return if @struct[:distro]
    @struct[:distro] = `uname -s`.strip.downcase
    @struct[:release] = `uname -r`.strip.downcase
    @struct
  end
  private :_prepare

  def query(search)
    _prepare
    super(search)
  end
end
