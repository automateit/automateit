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
      interpreter.sh(_add_or_remove_command(:add, opts))
    end
  end

  # See AddressManager#remove
  def remove(opts)
    _remove_helper(opts) do |opts|
      interpreter.sh(_add_or_remove_command(:remove, opts))
      interpreter.sh("ifconfig %s unplumb" % _interface_and_label(opts))
      true
    end
  end

  # FIXME generic?
  def _interface_and_label(opts)
    return(
      if opts[:device] and not opts[:label]
        opts[:device]
      elsif opts[:device] and opts[:label]
        "%s:%s" % [opts[:device], opts[:label]]
      else
        raise ArgumentError.new("Can't derive interface and label for: #{opts.inspect}")
      end
    )
  end

  # FIXME generic?
  def _add_or_remove_command(action, opts)
    _raise_unless_available
    action = :del if action.to_sym == :remove

    _normalize_opts(opts)

    ### ifconfig hme0 192.9.2.106 netmask 255.255.255.0 up
    ### ifconfig hme0:1 172.40.30.4 netmask 255.255.0.0 up

    ipcmd = "ifconfig"
    ipcmd << " " << _interface_and_label(opts)
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
    return `ifconfig -a`.scan(/^([^ ]+):\s+/s).flatten
  end

  # See AddressManager#addresses
  def addresses()
    _raise_unless_available
    return `ifconfig -a`.scan(/\s+inet\s+([^\s]+)\s+/).flatten
  end
end

