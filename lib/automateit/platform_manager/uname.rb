# == PlatformManager::Uname
#
# A PlatformManager driver that uses the Unix +uname+ command to provide
# basic information about the platform.
class AutomateIt::PlatformManager::Uname < AutomateIt::PlatformManager::Struct
  depends_on :programs => %w(uname)

  def suitability(method, *args) # :nodoc:
    # Level must be greater than Struct's
    return available? ? 2 : 0
  end

  def setup(opts={}) # :nodoc:
    super(opts)
    if available?
      @struct[:os]   ||= @@struct_cache[:os]   ||= `uname -s`.chomp.downcase
      @struct[:arch] ||= @@struct_cache[:arch] ||= `uname -m`.chomp.downcase
=begin
      # This method is 20% faster, but is it less portable because of the combined calls?
      @struct[:os] and @struct[:arch] or begin
        output = `uname -s -m`.chomp.downcase
        os, arch = output.split(/\s+/)
        @struct[:os]   = @@struct_cache[:os]   = os
        @struct[:arch] = @@struct_cache[:arch] = arch
      end
=end
    end
  end
end
