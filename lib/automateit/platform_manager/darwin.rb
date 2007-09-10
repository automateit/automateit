# == PlatformManager::Darwin
#
# A PlatformManager driver for Apple's Darwin.
class AutomateIt::PlatformManager::Darwin < AutomateIt::PlatformManager::Struct
  depends_on :files => ["/usr/sbin/scutil"], :programs => ["which"]

  def suitability(method, *args) # :nodoc:
    # Must be higher than PlatformManager::Struct
    return available? ? 3 : 0
  end

  def _prepare
    return if @struct[:release]
    @struct[:os] = "darwin"
    @struct[:arch] = `uname -p`.strip.downcase
    @struct[:distro] = "apple"
    @struct[:release] = `uname -r`.strip.downcase
    @struct
  end
  private :_prepare

  def query(search)
    _prepare
    super(search)
  end

  def single_vendor?
    return true
  end
end
