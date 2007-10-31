# == AddressManager::BSD
#
# An AddressManager driver for operating systems using a BSD-like ifconfig.
# Driver provides querying addresses and interfaces.
class AutomateIt::AddressManager::BSD < AutomateIt::AddressManager::BaseDriver
  def self.token
    :bsd
  end

  depends_on :programs => %w(ifconfig uname),
    :callbacks => lambda{`uname -s`.match(/openbsd|freebsd|sunos/i)}

  def suitability(method, *args) # :nodoc:
    available? ? 2 : 0
  end

  # See AddressManager#interfaces
  def interfaces()
    _raise_unless_available
    return `ifconfig -a`.scan(/^([^\s]+):\s+/s).flatten
  end

  # See AddressManager#addresses
  def addresses()
    _raise_unless_available
    return `ifconfig -a`.scan(/\s+inet\s+([^\s]+)\s+/).flatten
  end
end
