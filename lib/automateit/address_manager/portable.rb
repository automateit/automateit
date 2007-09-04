module AutomateIt
  class AddressManager
    # == AddressManager::Portable
    #
    # A pure-Ruby, portable driver for the AddressManager which provides
    # minimal support for querying the hostname using sockets. Although it
    # lacks advanced features found in other drivers, it will work on all
    # platforms.
    class Portable < Plugin::Driver
      include ResolvHelpers

      def suitability(method, *args) # :nodoc:
        return 1
      end

      # See AddressManager#has?
      def has?(opts)
        raise NotImplementedError.new("this driver doesn't support queries for devices or labels") if opts[:device] or opts[:label]
        result = true
        result &= addresses.include?(opts[:address]) if opts[:address]
        return result
      end

      # See AddressManager#hostnames
      def hostnames
        names = Set.new
        names << Socket.gethostname
        names.merge(Socket.gethostbyname(Socket.gethostname)[1]) rescue SocketError

        names.each{|name| names.merge(hostnames_for(name))}
        names << "localhost"
        return names.to_a.sort
      end

      # See AddressManager#addresses
      def addresses
        return ["127.0.0.1", TCPSocket.gethostbyname(Socket.gethostname)[3]]
      end
    end
  end
end
