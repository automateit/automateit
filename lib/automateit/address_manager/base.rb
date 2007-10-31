# == AddressManager::BaseDriver
#
# Base class for all AddressManager drivers.
class AutomateIt::AddressManager::BaseDriver< AutomateIt::Plugin::Driver
  public

  # See AddressManager#hostnames
  def hostnames()
    # NOTE: depends on driver's implementation of addresses
    names = manager.addresses.inject(Set.new) do |sum, address|
      # Some addresses can't be resolved, bummer.
      sum.merge(Resolv.getnames(address)) rescue Resolv::ResolvError; sum
    end
    names << Socket.gethostname
    names.merge(Socket.gethostbyname(Socket.gethostname)[1]) rescue SocketError

    names.each{|name| names.merge(hostnames_for(name))}
    names << "localhost"
    return names.to_a.sort
  end

  # See AddressManager#hostname_for
  def hostnames_for(hostname)
    results = []
    elements = hostname.split(".")
    for i in 1..elements.size
      results << elements[0..i-1].join(".")
    end
    return results.to_a.sort
  end

  # See AddressManager#has?
  def has?(opts)
    raise ArgumentError.new(":device or :address must be specified") unless opts[:device] or opts[:address]
    result = true
    result &= manager.interfaces.include?(opts[:device]) if opts[:device] and not opts[:label]
    result &= manager.interfaces.include?(opts[:device]+":"+opts[:label]) if opts[:device] and opts[:label]
    result &= manager.addresses.include?(opts[:address]) if opts[:address]
    return result
  end

  #-----------------------------------------------------------------------

  protected

  # Convert a mask to a CIDR.
  #
  # Example:
  #  mask_to_cidr("255.255.255.0") # => 24
  def mask_to_cidr(mask)
    # TODO Find less horrible solution which can handle IPv6.
    result = ''
    for chunk in mask.split(".")
      result += dec2bin(chunk.to_i)
    end
    return result.scan(/1/).size
  end

  # Convert CIDR to mask.
  #
  # Example:
  #  cidr_to_mask(24) # => "255.255.255.0"
  def cidr_to_mask(cidr)
    # TODO Find less horrible solution which can handle IPv6.
    require 'ipaddr'
    IPAddr.new("0.0.0.0/#{cidr}").inspect.match(%r{/([\d\.]+)>})[1]
  end

  # Convert a decimal number to binary notation.
  #
  # Example:
  #  dec2bin(255) # => "11111111"
  def dec2bin(n)
    # dec2bin(255)
    return "%b" % n
  end

  # Convert a binary number to decimal.
  #
  # Example:
  #  bin2dec("11111111") # => 255
  def bin2dec(s)
    return s.to_i(2)
  end

  # Helper for #add method.
  def _add_helper(opts, &block)
    opts[:announcements] = opts[:announcements].to_i || AutomateIt::AddressManager::DEFAULT_ANNOUNCEMENTS
    raise SecurityError.new("you must be root") unless superuser?
    raise ArgumentError.new(":device and :address must be specified") unless opts[:device] and opts[:address]
    return false if manager.has?(opts)
    block.call(opts)
    return true
  end

  # Helper for #remove method.
  def _remove_helper(opts, &block)
    return false unless manager.has?(opts)
    raise SecurityError.new("you must be root") unless superuser?
    raise ArgumentError.new(":device and :address must be specified") unless opts[:device] and opts[:address]
    return block.call(opts)
  end

  # Alter +opts+ hash to add alternative names for various options.
  def _normalize_opts(opts)
    # Accept common alternative names
    opts[:mask] ||= opts[:netmask] if opts[:netmask]
    opts[:alias] ||= opts[:alias] if opts[:alias]
    opts[:device] ||= opts[:interface] if opts[:interface]

    if opts[:mask] and not opts[:mask].match(/\./)
      opts[:mask] = cidr_to_mask(opts[:mask])
    end

    return opts
  end

  # Return the interface and label specified in +opts+ hash, e.g., "eth0:1".
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

  # Returns a string used to construct an ifconfig command, e.g.
  #   ifconfig hme0 192.9.2.106 netmask 255.255.255.0 up
  #   ifconfig hme0:1 172.40.30.4 netmask 255.255.0.0 up
  #
  # Options:
  # * :device -- Interface, e.g., "eth0". String.
  # * :label -- Alias label, e.g., "1". String.
  # * :address -- IP address, e.g., "127.0.0.1". String.
  # * :mask -- Netmask, e.g., "255.255.255.0" or 24. String or Fixnum.
  #
  # Helper options:
  # * :append -- Array of strings to append to end of command, e.g., ["-alias"].
  # * :prepend -- Array of strings to prepend to string, adding them after after "ifconfig", e.g., ["inet"].
  # * :state -- Whether to list "up" and "down" in command. Defaults to true.
  def _ifconfig_helper(action, opts, helper_opts={})
    _raise_unless_available

    # Translate common names
    action = :del if action.to_sym == :remove

    # Defaults
    _normalize_opts(opts)
    helper_opts[:state] = true unless helper_opts[:state] == false

    ipcmd = "ifconfig"
    ipcmd << " " << _interface_and_label(opts)
    if helper_opts[:prepend]
      ipcmd << " " << helper_opts[:prepend].join(" ")
    end
    ipcmd << " %s" % opts[:address]
    ipcmd << " netmask %s" % opts[:mask] if opts[:mask]
    if helper_opts[:state]
      ipcmd << " up" if action == :add
      ipcmd << " down" if action == :del
    end
    if helper_opts[:append]
      ipcmd << " " << helper_opts[:append].join(" ")
    end
    return ipcmd
  end
end
