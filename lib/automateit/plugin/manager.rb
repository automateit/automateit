module AutomateIt
  class Plugin
    # == Plugin::Manager
    #
    # A manager provides high-level wrappers for features, e.g.
    # installing software packages. It does not actually implement these
    # features, but instead manages a set of drivers. When one of the manager's
    # wrapper methods is called, it queries the drivers to find the most
    # suitable one and dispatches the user's request to that driver.
    #
    # For example, the PlatformManager is a Manager class that manages a set of
    # Driver instances, including PlatformManager::Uname and
    # PlatformManager::LSB. When you invoke the high-level
    # PlatformManager#query wrapper method, it interrogates the drivers to find
    # which one is best-suited for this method and then dispatches the request
    # to that driver's low-level implementation of this method.
    #
    # The manager subclasses typically have no functionality of their own and
    # just contain wrapper methods and documentation.
    class Manager < Base
      # Array of all managers.
      cattr_accessor :classes
      self.classes = []

      # Register managers.
      def self.inherited(subclass) # :nodoc:
        classes << subclass unless classes.include?(subclass)
      end

      # Declare that this manager class is abstract. It can be subclassed but
      # will not be instantiated by the Interpreter.
      def self.abstract_manager
        classes.delete(self)
      end

      # List of aliased methods for this manager, populated by ::alias_methods.
      class_inheritable_accessor :aliased_methods

      # Methods to alias into the Interpreter, specified as an array of symbols.
      def self.alias_methods(*methods)
        self.aliased_methods ||= Set.new
        self.aliased_methods.merge(methods.flatten)
      end

      # Drivers for this manager as a hash of driver tokens to driver
      # instances.
      attr_accessor :drivers

      # Driver classes used by this Manager.
      def self.driver_classes
        Driver.classes[token] || []
      end

      # Options:
      # * :default -- The token of the driver to set as the default.
      def setup(opts={})
        super(opts)

        @default ||= nil

        instantiate_drivers

        if driver = opts[:default] || opts[:driver]
          default(opts[:default]) if opts[:default]
          @drivers[driver].setup(opts)
        end
      end

      # Instantiate drivers for this manager. This method is smart enough that
      # it can be called multiple times and will only instantiate drivers it
      # hasn't instantiated yet. All drivers will share an instance of the
      # Interpreter, thus providing common state storage.
      def instantiate_drivers
        @drivers ||= {}
        self.class.driver_classes.each do |driver_class|
          driver_token = driver_class.token
          unless @drivers[driver_token]
            @drivers[driver_token] = driver_class.allocate
          end
        end
        self.class.driver_classes.each do |driver_class|
          driver_token = driver_class.token
          @drivers[driver_token].setup(
            :interpreter => @interpreter, :manager => self)
        end
      end

      # Returns the Driver with the specified token. E.g., +:apt+ will return
      # the +APT+ driver.
      def [](token)
        return @drivers[token]
      end

      # Manipulate the default driver. Without arguments, gets the driver token
      # as a symbol. With argument, sets the default driver to the +token+,
      # e.g., the argument <tt>:apt</tt> will make the +APT+ driver the default.
      def default(token=nil)
        if token.nil?
          @default
        else
          @default = token
        end
      end

      # Set the default driver to the +token+. See also #default.
      def default=(token)
        default(token)
      end

      # Dispatch a method by guessing its name. This is the recommended way to
      # write wrappers for a Manager methods.
      #
      # Example:
      #   class MyManager < Plugin::Manager
      #     # Your RDoc here
      #     def my_method(*args)
      #       # Will guess that you want to +dispatch_to+ the +my_method+ by
      #       # introspecting the name of the wrapper method.
      #       dispatch(*args)
      #     end
      #     ...
      #   end
      def dispatch(*args, &block)
        # Extract caller's method as symbol to save user from having to specify it
        method = caller[0].match(/:in `(.+?)'/)[1].to_sym
        dispatch_to(method, *args, &block)
      end

      # Dispatch the +method+ with +args+ and +block+ to the appropriate
      # driver. If the arguments include an option of the form <tt>:with =>
      # :mytoken</tt> argument, then the method will be dispatched to the
      # driver represented by <tt>:mytoken</tt>. If no :with argument is
      # specified, the most-suitable driver will be automatically selected. If
      # no suitable driver is available, a NotImplementedError will be raised.
      #
      # Examples:
      #   # Run 'hostnames' method on most appropriate AddressManager driver:
      #   address_manager.dispatch_to(:hostnames)
      #
      #   # Run AddressManager::Portable#hostnames
      #   address_manager.dispatch_to(:hostnames, :with => :portable)
      #
      # You will typically not want to use this method directly and instead
      # write wrappers that call #dispatch because it can guess the name of
      # the +method+ argument for you.
      def dispatch_to(method, *args, &block)
        list, options = args_and_opts(*args)
        driver = \
          if options and options[:with]
            @drivers[options[:with].to_sym]
          elsif default
            @drivers[default.to_sym]
          else
            driver_for(method, *args, &block)
          end
        driver.send(method, *args, &block)
      end

      # Same as #dispatch_to but returns nil if couldn't dispatch, rather than
      # raising an exception.
      def dispatch_safely_to(method, *args, &block)
        begin
          dispatch_to(method, *args, &block)
        rescue NotImplementedError
          nil
        end
      end

      # Same as #dispatch but returns nil if couldn't dispatch, rather than
      # raising an exception.
      def dispatch_safely(*args, &block)
        method = caller[0].match(/:in `(.+?)'/)[1].to_sym
        dispatch_safely_to(method, *args, &block)
      end

      # Returns structure which helps choose a suitable driver for the +method+
      # and +args+. Result is a hash of driver tokens and their suitability
      # levels.
      #
      # For example, if we ask the AddressManager for suitability levels for
      # the AddressManager#hostnames method, we might find that there are two
      # drivers (:portable is the token for AddressManager::Portable) and that
      # the :linux driver is most appropriate because it has the highest
      # suitability level:
      #
      #   address_manager.driver_suitability_levels_for(:hostnames)
      #   # => {:portable=>1, :linux=>2}
      def driver_suitability_levels_for(method, *args, &block)
        results = {}
        @drivers.each_pair do |name, driver|
          next unless driver.respond_to?(method)
          results[name] = driver.suitability(method, *args, &block)
        end
        return results
      end

      # Get the most suitable driver for this +method+ and +args+. Uses
      # automatic-detection routines and returns the most suitable driver
      # instance found, else raises a NotImplementedError if no suitable driver
      # is found.
      def driver_for(method, *args, &block)
        begin
          driver, level = driver_suitability_levels_for(method, *args, &block).sort_by{|k,v| v}.last
        rescue IndexError
          driver = nil
          level = -1
        end
        if driver and level > 0
          return @drivers[driver]
        else
          raise NotImplementedError.new("can't find driver for method '#{method}' with arguments: #{args.inspect}")
        end
      end

      # Is a driver available for this +method+ and +args+? Uses
      # automatic-detection routines and returns a boolean to indicate if a
      # suitable driver is available. Unlike #driver_for, this will not raise
      # an exception.
      def available?(method, *args, &block)
        begin
          driver_for(method, *args, &block)
          true
        rescue NotImplementedError
          false
        end
      end
    end
  end
end
