module AutomateIt
  # == AddressManager
  #
  # The AddressManager provides a way to query, add and remove network
  # addresses on a host.
  class AddressManager < Plugin::Manager
    require 'automateit/address_manager/resolv_helpers'
    require 'automateit/address_manager/portable'
    require 'automateit/address_manager/linux'

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
  end
end
