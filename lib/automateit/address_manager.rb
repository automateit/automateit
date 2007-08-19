require 'automateit'

module AutomateIt
  class AddressManager < Plugin::Manager
    # Does host have an address or interface? Arguments hash must include
    # either a :device (e.g. "eth0") or :address (e.g. "10.0.0.10"), and an
    # optional :label (e.g. "foo"). Note that an interface is the combination
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
    # Arguments hash must include either a :device (e.g. "eth0") or :address
    # (e.g. "10.0.0.10"), and an optional :label (e.g. "foo") and :mask (e.g.
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
    DEFAULT_ANNOUNCEMENTS = 3

    # Remove address from host if it has it. Requires root-level access.
    # Returns +true+ if action was taken and succeeded.
    #
    # Arguments hash must include either a :device (e.g. "eth0") or :address
    # (e.g. "10.0.0.10"), and an optional :label (e.g. "foo") and :mask (e.g.
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

    #-----------------------------------------------------------------------

    module ResolvHelpers
      require 'resolv'

      def hostnames()
        names = addresses.inject(Set.new) do |sum, address|
          # Some addresses can't be resolved, bummer.
          sum.merge(Resolv.getnames(address)) rescue Resolv::ResolvError; sum
        end
        names.each{|name| names.merge(hostnames_for(name))}
        return names.to_a.sort
      end

      def hostnames_for(hostname)
        results = []
        elements = hostname.split(".")
        for i in 1..elements.size
          results << elements[0..i-1].join(".")
        end
        return results.to_a.sort
      end
    end

    #-----------------------------------------------------------------------

    class Linux < Plugin::Driver
      include ResolvHelpers

      depends_on :programs => %w(ifconfig ip arping)

      def suitability(method, *args)
        return available? ? 1 : 0
      end

      def has?(opts)
        raise ArgumentError.new(":device or :address must be specified") unless opts[:device] or opts[:address]
        result = true
        result &= interfaces.include?(opts[:device]) if opts[:device] and not opts[:label]
        result &= interfaces.include?(opts[:device]+":"+opts[:label]) if opts[:device] and opts[:label]
        result &= addresses.include?(opts[:address]) if opts[:address]
        return result
      end

      def add(opts)
        announcements = opts[:announcements].to_i || AutomateIt::AddressManager::DEFAULT_ANNOUNCEMENTS
        raise SecurityEror.new("you must be root") unless Process.euid.zero?
        raise ArgumentError.new(":device and :address must be specified") unless opts[:device] and opts[:address]
        return false if has?(opts)
        #run(%{ip address add #{ip}/#{mask} brd + dev #{device} label #{device}:#{label}})
        if interpreter.sh(_add_or_remove_command(:add, opts))
          #run(%{arping -q -c 3 -A -I #{device} #{ip} &})
          return interpreter.sh("arping -q -c #{announcements} -A -I #{opts[:device]} #{opts[:address]}")
        else
          return false
        end
      end

      def remove(opts)
        return false unless has?(opts)
        raise SecurityEror.new("you must be root") unless Process.euid.zero?
        raise ArgumentError.new(":device and :address must be specified") unless opts[:device] and opts[:address]
        return interpreter.sh(_add_or_remove_command(:remove, opts))
      end

      def _add_or_remove_command(action, opts)
        _raise_unless_available
        case action.to_sym
        when :add
          # Accept
        when :remove
          # Rename
          action = :del
        else
          raise ArgumentError.new("action must be :add or :remove")
        end

        # Accept common alternative names
        opts[:mask] ||= opts[:netmask] if opts[:netmask]
        opts[:alias] ||= opts[:alias] if opts[:alias]
        opts[:device] ||= opts[:interface] if opts[:interface]

        # ip address add 10.0.0.123/24 brd + dev eth0 label eth0:foo
        ipcmd = "ip address #{action} #{opts[:address]}"
        ipcmd += "/#{opts[:mask]}" if opts[:mask]
        ipcmd += " brd + dev #{opts[:device]}"
        ipcmd += " label #{opts[:device]}:#{opts[:label]}" if opts[:label]
        return ipcmd
      end
      private :_add_or_remove_command

      def interfaces()
        _raise_unless_available
        return `ifconfig`.scan(/^(\w+?(?::\w+)?)\b\s+Link/).flatten
      end

      def addresses()
        _raise_unless_available
        return `ifconfig`.scan(/inet6? addr:\s*(.+?)\s+/).flatten
      end
    end
  end
end
