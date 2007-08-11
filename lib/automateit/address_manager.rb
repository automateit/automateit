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
    # Example:
    #   add(:address => "10.0.0.10", :mask => 24, :device => "eth0", :label => "foo")
    def add(opts) dispatch(opts) end

    # Remove address from host if it has it. Requires root-level access.
    # Returns +true+ if action was taken and succeeded.
    #
    # Arguments hash is identical to that used by #add. 
    def remove(opts) dispatch(opts) end

    # Array of addresses for this host. Example:
    #   addresses
    #   => ["10.0.0.10", "127.0.0.1"]
    def addresses() dispatch() end

    # Array of interfaces for this host. Example:
    #   interfaces
    #   => ["eth0", "lo"]
    def interfaces() dispatch() end

    class Linux < Plugin::Driver
      def suitability(method, *args)
        @suitable ||= interpreter.eval{which("ifconfig") and which("ip") and which("arping")}
        return @suitable ? 1 : -1
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
        return false if has?(opts)
        raise SecurityEror.new("you must be root") unless Process.euid.zero?
        raise ArgumentError.new(":device and :address must be specified") unless opts[:device] and opts[:address]
        ipcmd = "ip address add #{opts[:address]}"
        ipcmd += "/#{opts[:mask]}" if opts[:mask]
        ipcmd += " brd + dev #{opts[:device]}"
        ipcmd += " label #{opts[:device]}:#{opts[:label]}" if opts[:label]
        #run(%{ip address add #{ip}/#{mask} brd + dev #{device} label #{device}:#{label}})
        if interpreter.sh(ipcmd)
          #run(%{arping -q -c 3 -A -I #{device} #{ip} &})
          return interpreter.sh("arping -q -c 3 -A -I #{opts[:device]} #{opts[:address]} &")
        else
          return false
        end
      end

      def remove(opts)
        return false unless has?(opts)
        raise SecurityEror.new("you must be root") unless Process.euid.zero?
        raise ArgumentError.new(":device and :address must be specified") unless opts[:device] and opts[:address]
        ipcmd = "ip address del #{opts[:address]}"
        ipcmd += "/#{opts[:mask]}" if opts[:mask]
        ipcmd += " brd + dev #{opts[:device]}"
        ipcmd += " label #{opts[:device]}:#{opts[:label]}" if opts[:label]
        #run(%{ip address del #{ip}/#{mask} brd + dev #{device} label #{device}:#{label}})
        return interpreter.sh(ipcmd)
      end

      def interfaces()
        return `ifconfig`.scan(/^(\w+?(?::\w+)?)\b\s+Link/).flatten
      end

      def addresses()
        return `ifconfig`.scan(/inet6? addr:\s*(.+?)\s+/).flatten
      end
    end
  end
end
