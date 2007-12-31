# == PlatformManager::LSB
#
# A PlatformManager driver for LSB (Linux Standards Base) systems. The
# platform doesn't actually need to be Linux, but simply has to provide an
# <tt>lsb_release</tt> command.
class AutomateIt::PlatformManager::LSB < AutomateIt::PlatformManager::Uname
  LSB_RELEASE = "lsb_release"

  depends_on :programs => [LSB_RELEASE]

  def suitability(method, *args) # :nodoc:
    # Level must be greater than Uname and Debian
    return available? ? 4 : 0
  end

  def setup(opts={}) # :nodoc:
    super(opts) # Rely on Uname to set :os and :arch
    @struct[:distro]  ||= @@struct_cache[:distro]
    @struct[:release] ||= @@struct_cache[:release]
    if available?
      unless @struct[:distro] and @struct[:release]
        hash = _parse_lsb_release_data(_read_lsb_release_data)
        @struct[:distro]  ||= @@struct_cache[:distro]  ||= hash["Distributor ID"].to_s.downcase
        @struct[:release] ||= @@struct_cache[:release] ||= hash["Release"].to_s.downcase
      end
    end
  end

protected

  # Returns the LSB data for this platform's Distributor and ID
  def _read_lsb_release_data
    # TODO Consider parsing files directly to avoid the overhead of this command.
    #
    # Do NOT use 'lsb_release -a' because this takes a few seconds. Telling
    # 'lsb_release' which fields we want makes it much faster.
    `"#{LSB_RELEASE}" --release --id`
  end

  # Parses LSB data into a hash.
  def _parse_lsb_release_data(data)
    data.scan(/^([^:]+):\s+([^\n]+)/).inject({}){|s,v| s[v.first] = v.last; s}
  end
end
