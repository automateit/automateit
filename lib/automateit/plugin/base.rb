module AutomateIt
  class Plugin
    # == Plugin::Base
    #
    # An AutomateIt Plugin provides the Interpreter with the functionality that
    # users actually care about, such as installing packages or adding users.
    # The Plugin::Base class isn't useful by itself but provides behavior
    # that's inherited by the Plugin::Manager and Plugin::Driver classes.
    class Base < Common
      def setup(opts={}) # :nodoc:
        super(opts)
        @interpreter ||= opts[:interpreter] \
          || AutomateIt::Interpreter.new(:parent => self)
      end

      # Get token for the plugin. The token is a symbol that represents the
      # classname of the underlying object.
      #
      # Example:
      #   AddressManager.token # => :address_manager
      #   AddressManager::Portable.token => :portable
      def token
        self.class.token
      end

      # See #token.
      def self.token
        return to_s.demodulize.underscore.to_sym
      end
    end
  end
end
