# == AddressManager::Linux
#
# A Linux-specific driver for the AddressManager provides complete support for
# querying, adding and removing addresses on platforms that feature Linux-like
# tools.
class AutomateIt::AddressManager::Linux < AutomateIt::AddressManager::BaseDriver
  depends_on :programs => "ifconfig", 
    :callbacks => lambda{`ifconfig --version 2>&1`.match(/net-tools/)}

  def suitability(method, *args) # :nodoc:
    available? ? 2 : 0
  end

  # See AddressManager#has?
  def has?(opts)
    raise ArgumentError.new(":device or :address must be specified") unless opts[:device] or opts[:address]
    result = true
    result &= interfaces.include?(opts[:device]) if opts[:device] and not opts[:label]
    result &= interfaces.include?(opts[:device]+":"+opts[:label]) if opts[:device] and opts[:label]
    result &= addresses.include?(opts[:address]) if opts[:address]
    return result
  end

  # See AddressManager#add
  def add(opts)
    announcements = opts[:announcements].to_i || AutomateIt::AddressManager::DEFAULT_ANNOUNCEMENTS
    raise SecurityError.new("you must be root") unless superuser?
    raise ArgumentError.new(":device and :address must be specified") unless opts[:device] and opts[:address]
    return false if has?(opts)
    interpreter.sh(_add_or_remove_command(:add, opts))
    if interpreter.which("arping")
      interpreter.sh("arping -q -c #{announcements} -w #{announcements} -I #{opts[:device]} #{opts[:address]}")
    end
    return true
  end

  # See AddressManager#remove
  def remove(opts)
    return false unless has?(opts)
    raise SecurityError.new("you must be root") unless superuser?
    raise ArgumentError.new(":device and :address must be specified") unless opts[:device] and opts[:address]
    return interpreter.sh(_add_or_remove_command(:remove, opts))
  end

  def _add_or_remove_command(action, opts)
    _raise_unless_available
    action = :del if action.to_sym == :remove

    # Accept common alternative names
    opts[:mask] ||= opts[:netmask] if opts[:netmask]
    opts[:alias] ||= opts[:alias] if opts[:alias]
    opts[:device] ||= opts[:interface] if opts[:interface]

    if opts[:mask] and not opts[:mask].match(/\./)
      opts[:mask] = cidr_to_mask(opts[:mask])
    end

    ipcmd = "ifconfig"
    ipcmd << " %s" % opts[:device] if opts[:device] and not opts[:label]
    ipcmd << " %s:%s" % [opts[:device], opts[:label]] if opts[:device] and opts[:label]
    ipcmd << " %s" % opts[:address]
    ipcmd << " netmask %s" % opts[:mask] if opts[:mask]
    ipcmd << " up" if action == :add
    ipcmd << " down" if action == :del
    return ipcmd
  end
  private :_add_or_remove_command

  # See AddressManager#interfaces
  def interfaces()
    _raise_unless_available
    return `ifconfig`.scan(/^(\w+?(?::\w+)?)\b\s+Link/).flatten
  end

  # See AddressManager#addresses
  def addresses()
    _raise_unless_available
    return `ifconfig`.scan(/inet6? addr:\s*(.+?)\s+/).flatten
  end
end
