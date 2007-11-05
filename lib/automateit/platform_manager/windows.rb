# == PlatformManager::Windows
#
# A PlatformManager driver for Windows systems.
class AutomateIt::PlatformManager::Windows < AutomateIt::PlatformManager::Struct
  def available?
    return RUBY_PLATFORM.match(/mswin/) ? true : false
  end

  def suitability(method, *args) # :nodoc:
    # Must be higher than PlatformManager::Struct
    return available? ? 3 : 0
  end

  def _prepare
    return if @struct[:release]
    @struct[:os] = "windows"
    @struct[:arch] = ENV["PROCESSOR_ARCHITECTURE"]
    @struct[:distro] = "microsoft"

    # VER values: http://www.ss64.com/nt/ver.html
    ver = `ver`.strip
    if match = ver.match(/Windows (\w+)/)
      @struct[:release] = match[1].downcase
    elsif match = ver.match(/Windows \[Version 6\.0\./)
      @struct[:release] = "vista"
    end

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
