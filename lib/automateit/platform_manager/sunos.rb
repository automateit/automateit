# == PlatformManager::SunOS
#
# A PlatformManager driver for SunOS.
class AutomateIt::PlatformManager::SunOS < AutomateIt::PlatformManager::Uname
  def self.token
    :sunos
  end

  depends_on \
    :programs => %w(uname),
    :callbacks => [lambda {
      begin
        not `uname -s`.match(/SunOS/i).nil?
      rescue
        false
      end
    }]

  def suitability(method, *args) # :nodoc:
    # Must be higher than PlatformManager::Struct and Uname
    return available? ? 3 : 0
  end

  def _prepare
    return if @struct[:release]
    @struct[:distro] = "sun"
    @struct[:release] = `uname -r`.strip.downcase
    @struct
  end

  def query(search)
    _prepare
    super(search)
  end

  def single_vendor?
    return true
  end
end
