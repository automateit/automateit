# == AddressManager::SunOS
#
# A SunOS-specific driver for the AddressManager provides complete support for
# querying, adding and removing addresses.
class AutomateIt::AddressManager::SunOS < AutomateIt::AddressManager::BaseDriver
  def self.token
    :sunos
  end

  depends_on :programs => %w(ifconfig uname),
    :callbacks => lambda{`uname -s`.match(/sunos/i)}

  def suitability(method, *args) # :nodoc:
    available? ? 2 : 0
  end

  # See AddressManager#add
  def add(opts)
    _add_helper(opts) do |opts|
      interpreter.sh("ifconfig %s plumb" % _interface_and_label(opts))
      interpreter.sh(_ifconfig_helper(:add, opts))
    end
  end

  # See AddressManager#remove
  def remove(opts)
    _remove_helper(opts) do |opts|
      interpreter.sh(_ifconfig_helper(:remove, opts))
      interpreter.sh("ifconfig %s unplumb" % _interface_and_label(opts))
      true
    end
  end

  # See AddressManager#interfaces
  def interfaces()
    _raise_unless_available
    return `ifconfig -a`.scan(/^([^ ]+):\s+/s).flatten
  end

  # See AddressManager#addresses
  def addresses()
    _raise_unless_available
    return `ifconfig -a`.scan(/\s+inet\s+([^\s]+)\s+/).flatten
  end
end

