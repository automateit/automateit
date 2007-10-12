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

  # See AddressManager#add
  def add(opts)
    _add_helper(opts) do |opts|
      interpreter.sh(_add_or_remove_command(:add, opts))
      if interpreter.which("arping")
        interpreter.sh("arping -q -c #{opts[:announcements]} -w #{opts[:announcements]} -I #{opts[:device]} #{opts[:address]}")
      end
    end
  end

  # See AddressManager#remove
  def remove(opts)
    _remove_helper(opts) do |opts|
      interpreter.sh(_add_or_remove_command(:remove, opts))
    end
  end

  def _add_or_remove_command(action, opts)
    _raise_unless_available
    action = :del if action.to_sym == :remove

    _normalize_opts(opts)

    ipcmd = "ifconfig"
    ipcmd << " %s" % opts[:device] if opts[:device] and not opts[:label]
    ipcmd << " %s:%s" % [opts[:device], opts[:label]] if opts[:device] and opts[:label]
    ipcmd << " %s" % opts[:address]
    ipcmd << " netmask %s" % opts[:mask] if opts[:mask]
    ipcmd << " up" if action == :add
    ipcmd << " down" if action == :del
    return ipcmd
  end
  protected :_add_or_remove_command

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
