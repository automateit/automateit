require 'automateit'

module AutomateIt
  class AddressManager < Plugin::Manager
    def has?(opts) dispatch(opts) end
    
    def add(opts) dispatch(opts) end

    def remove(opts) dispatch(opts) end

    class Linux < Plugin::Driver
      def suitability(method, *args)
        @suitable ||= interpreter.eval{which("ifconfig") and which("ip") and which("arping")}
        return @suitable ? 1 : -1
      end

      # b AutomateIt::AddressManager::Linux.has?
      def has?(opts)
        data = `ifconfig`
        result = true
        result &= data.match(/\binet6?\s+addr:\s*#{opts[:address]}\b/) if opts[:address]
        result &= data.match(/^#{opts[:device]}\b/) if opts[:device] && ! opts[:label]
        result &= data.match(/^#{opts[:device]}:#{opts[:label]}\b/) if opts[:device] && opts[:label]
        return result
      end

      def add(opts)
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
        raise ArgumentError.new(":device and :address must be specified") unless opts[:device] and opts[:address]
        ipcmd = "ip address del #{opts[:address]}"
        ipcmd += "/#{opts[:mask]}" if opts[:mask]
        ipcmd += " brd + dev #{opts[:device]}"
        ipcmd += " label #{opts[:device]}:#{opts[:label]}" if opts[:label]
        #run(%{ip address del #{ip}/#{mask} brd + dev #{device} label #{device}:#{label}})
        return interpreter.sh(ipcmd)
      end
    end
  end
end
