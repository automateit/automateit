module AutomateIt
  class AddressManager
    # == AddressManager::ResolvHelpers
    #
    # Helper methods for using Resolv library to lookup address information.
    module ResolvHelpers
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
    end
  end
end
