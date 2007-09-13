# == AddressManager
#
# The AddressManager provides a way to query, add and remove network
# addresses on a host.
class AutomateIt::AddressManager < AutomateIt::Plugin::Manager
  # Does host have an address or interface? Arguments hash must include
  # either a :device (e.g., "eth0") or :address (e.g., "10.0.0.10"), and an
  # optional :label (e.g., "foo"). Note that an interface is the combination
  # of a :device and :label, so "eth0" isn't the same as "eth0:foo".
  #
  # Examples on a host with address "10.0.0.10" on interface "eth0:foo":
  #   has?(:address => "10.0.0.10")
  #   => true
  #   has?(:address => "10.0.0.10", :device => "eth0")
  #   => false
  #   has?(:address => "10.0.0.10", :device => "eth0", :label => "foo")
  #   => true
  #   has?(:device => "eth0")
  #   => false
  #   has?(:device => "eth0", :label => "foo")
  #   => true
  def has?(opts) dispatch(opts) end

  # Add address to host if it doesn't have it. Requires root-level access.
  # Returns +true+ if action was taken and succeeded.
  #
  # Arguments hash must include either a :device (e.g., "eth0") or :address
  # (e.g., "10.0.0.10"), and an optional :label (e.g., "foo") and :mask (e.g.
  # "24").
  #
  # An optional number of ARP :announcements may be specified, defaulting to
  # AutomateIt::AddressManager::DEFAULT_ANNOUNCEMENTS. Drivers that handle
  # announcements will block an extra second while making each announcement.
  #
  # Example:
  #   add(:address => "10.0.0.10", :mask => 24, :device => "eth0",
  #     :label => "foo", :announcements => 3)
  def add(opts) dispatch(opts) end

  # Number of ARP announcements to make by default during #add.
  DEFAULT_ANNOUNCEMENTS = 3

  # Remove address from host if it has it. Requires root-level access.
  # Returns +true+ if action was taken and succeeded.
  #
  # Arguments hash must include either a :device (e.g., "eth0") or :address
  # (e.g., "10.0.0.10"), and an optional :label (e.g., "foo") and :mask (e.g.
  # "24").
  #
  # Example:
  #   remove(:address => "10.0.0.10", :mask => 24, :device => "eth0",
  #     :label => "foo")
  def remove(opts) dispatch(opts) end

  # Array of addresses for this host. Example:
  #   addresses
  #   => ["10.0.0.10", "127.0.0.1"]
  def addresses() dispatch() end

  # Array of interfaces for this host. Example:
  #   interfaces
  #   => ["eth0", "lo"]
  def interfaces() dispatch() end

  # Array of hostnames for this host, including variants by trying to resolve
  # names for all addresses owned by this host. Example:
  #   hostnames
  #   => ["kagami", "kagami.lucky-channel", "kagami.lucky-channel.jp"]
  def hostnames() dispatch() end

  # Array of hostname variants for this +hostname+. This method performs no
  # name resolution and simply infers a less qualified name from a more
  # qualified hostname argument. Example:
  #   hostnames_for("kagami.lucky-channel")
  #   => ["kagami", "kagami.lucky-channel"]
  #   hostnames_for("kagami")
  #   => ["kagami"]
  def hostnames_for(hostname) dispatch(hostname) end

  # Convert a mask to a CIDR.
  #
  # Example:
  #  mask_to_cidr("255.255.255.0") # => 24
  def mask_to_cidr(mask) dispatch(mask) end

  # Convert CIDR to mask.
  #
  # Example:
  #  cidr_to_mask(24) # => "255.255.255.0"
  def cidr_to_mask(cidr) dispatch(cidr) end

  # Convert a decimal number to binary notation.
  #
  # Example:
  #  dec2bin(255) # => "11111111"
  def dec2bin(n) dispatch(n) end

  # Convert a binary number to decimal.
  #
  # Example:
  #  bin2dec("11111111") # => 255
  def bin2dec(s) dispatch(s) end
end

# == AddressManager::BaseDriver
#
# Base class for all AddressManager drivers.
class AutomateIt::AddressManager::BaseDriver< AutomateIt::Plugin::Driver
  # See AddressManager#hostnames
  def hostnames()
    # NOTE: depends on driver's implementation of addresses
    names = addresses.inject(Set.new) do |sum, address|
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

  # See AddressManager#mask_to_cidr
  def mask_to_cidr(mask)
    # TODO Find less horrible solution which can handle IPv6.
    result = ''
    for chunk in mask.split(".")
      result += dec2bin(chunk.to_i)
    end
    return result.scan(/1/).size
  end

  # See AddressManager#cidr_to_mask
  def cidr_to_mask(cidr)
    # TODO Find less horrible solution which can handle IPv6.
    require 'ipaddr'
    IPAddr.new("0.0.0.0/#{cidr}").inspect.match(%r{/([\d\.]+)>})[1]
  end

  # See AddressManager#dec2bin
  def dec2bin(n)
    # dec2bin(255)
    return "%b" % n
  end

  # See AddressManager#bin2dec
  def bin2dec(s)
    return s.to_i(2)
  end
end

# Drivers
require 'automateit/address_manager/portable'
require 'automateit/address_manager/linux'
