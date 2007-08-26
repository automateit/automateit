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
        @interpreter ||= opts[:interpreter] || AutomateIt::Interpreter.new(:parent => self)
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

      # Running this method makes a class collect registrations into a
      # +classes+ class variable when inherited. For example, the
      # Plugin::Manager class uses this to keep track of what subclasses (e.g.
      # PlatformManager) are available. As plugins are defined, they'll be
      # recorded in this register so that the Interpreter can find what plugins
      # are available without anyone needing to create a hard-coded list.
      def self.collect_registrations
        cattr_accessor :classes

        self.classes = []

        def self.inherited(subclass) # :nodoc:
          classes << subclass unless classes.include?(subclass)
        end
      end

      # Remove this plugin from the class registry populated by
      # ::collect_registrations. This is useful for when you write an abstract
      # driver that shouldn't be made available to the Interpreter because you
      # want only its subclasses to be available.
      #
      # For example, note how only the MyConcreteManager is made available to
      # the Interpreter:
      #
      #   class MyAbstractManager < Plugin::Manager
      #     abstract_plugin
      #     ...
      #   end
      #
      #   class MyConcreteManager < MyAbstractManager
      #     ...
      #   end
      #
      #   interpreter = AutomateIt.new
      #   interpreter.plugins[:my_abstract_manager]
      #   # => nil
      #   interpreter.plugins[:my_concrete_manager]
      #   # => #<MyConcreteManager...>
      def self.abstract_plugin
        classes.delete(self) if classes.include?(self)
      end
    end
  end
end
