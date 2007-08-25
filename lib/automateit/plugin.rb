require 'automateit'

module AutomateIt
  class Plugin

    class Base < Common
      def setup(opts={})
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

      # See +#token+.
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

        def self.inherited(subclass)
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

    #-----------------------------------------------------------------------

    class Manager < Base
      collect_registrations

      class_inheritable_accessor :aliased_methods

      # Methods to alias into +Interpreter+, specified as an array of symbols.
      def self.alias_methods(*methods)
        if methods.empty?
          self.aliased_methods
        else
          self.aliased_methods ||= Set.new
          self.aliased_methods.merge(methods.flatten)
        end
      end

      attr_accessor :drivers

      # +Driver+ classes used by this +Manager+
      def self.driver_classes
        Driver.classes.select{|driver|driver.to_s.match(/^#{self}::/)}
      end

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
            @drivers[driver_token] = driver_class.new(:interpreter => @interpreter)
          end
        end
      end

      # Returns the +Driver+ with the specified token. E.g. +:apt+ will return
      # the +APT+ driver.
      def [](token)
        return @drivers[token]
      end

      # Manipulate the default driver. Without arguments, gets the driver token
      # as a symbol. With argument, sets the default driver to the +token+,
      # e.g. the argument +:apt+ will make the +APT+ driver the default.
      def default(token=nil)
        if token.nil?
          @default
        else
          @default = token
        end
      end

      # Set the default driver to the +token+. See also +#default+.
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
      # write wrappers that call +dispatch+ because it can guess the name of
      # the +method+ argument for you.
      def dispatch_to(method, *args, &block)
        list, options = args_and_opts(*args)
        driver = \
          if options and options[:with]
            @drivers[options[:with]]
          elsif default
            @drivers[default]
          else
            driver_for(method, *args, &block)
          end
        driver.send(method, *args, &block)
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
      # suitable driver is available. Unlike +#driver_for+, this will not raise
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

    #-----------------------------------------------------------------------

    class Driver < Base
      collect_registrations

      # Defines what this driver depends on the system for. Options:
      # * :files - Array of filenames that must exist.
      # * :directories - Array of directories that must exist.
      # * :programs - Array of programs, checked with +which+, that must exist.
      #
      # Example:
      #   class APT < Plugin::Driver
      #     depends_on :programs => %w(apt-get dpkg)
      #     # ...
      #  end
      def self.depends_on(opts)
        meta_eval do
          attr_accessor :_depends_on_opts, :_is_available, :_missing_dependencies
        end
        self._depends_on_opts = opts
      end

      # Is this driver available on this platform? Queries the dependencies set
      # by +depends_on+ to make sure that they're all present, otherwise raises
      # a NotImplementedError. If a driver author needs to do some other kind
      # of check, it's reasonable to override this method.
      #
      # For example, this method is used by the PackageManager driver for APT
      # to determine if the "apt-get" program is installed.
      #
      # The <tt>available?</tt> method is used to determine if the driver *can*
      # do the work, while the <tt>suitability</tt> method determines if the
      # driver *should* be automatically selected.
      def available?
        # Some drivers don't run +depends_on+, so assume they're available.
        return true unless self.class.respond_to?(:_depends_on_opts)
        opts = self.class._depends_on_opts

        # Driver said that it +depends_on :nothing+, so it's available.
        return true if opts == :nothing

        is_available = self.class._is_available
        if is_available.nil? and opts.nil?
          log.debug("don't know if driver #{self.class} is available, maybe it doesn't state what it +depends_on+")
          return false
        elsif is_available.nil?
          all_present = true
          missing = []
          for kind in [:files, :directories, :programs]
            next unless opts[kind]
            for item in opts[kind]
              present = \
                case kind
                when :files
                  File.exists?(item)
                when :directories
                  File.directory?(item)
                when :programs
                  # XXX Find less awkward way to check if a program exists. Can't use +shell_manager.which+ because that will use +dispatch+ and go into an infinite loop checking +available?+. The +which+ command isn't available on all platforms, so that failure must be handled as well.
                  begin
                    interpreter.shell_manager[:unix].which!(item)
                    true
                  rescue ArgumentError, NotImplementedError
                    false
                  end
                else
                  raise "unknown kind: #{kind}"
                end
              unless present
                all_present = false
                missing << item
              end
            end
          end
          self.class._missing_dependencies = missing
          self.class._is_available = all_present
          log.debug(PNOTE+"Driver #{self.class} #{all_present ? "is" : "isn't"} available")
        end
        return self.class._is_available
      end

      # Raise a NotImplementedError if this driver is called but is not
      # +available?+.
      def _raise_unless_available
        unless available?
          raise NotImplementedError.new(
            %{missing dependencies: #{self.class._missing_dependencies.join(", ")}})
        end
      end

      # What is this driver's suitability for automatic detection? The Manager
      # queries its drivers when there isn't a driver specified with a
      # <tt>:with</tt> or +default+ so it can choose a suitable driver for the
      # +method+ and +args+. Any driver that returns an integer 1 or greater
      # claims to be suitable. The Manager will then select the driver with the
      # highest suitability level. Drivers that return an integer less than 1
      # are excluded from automatic detection.
      #
      # The <tt>available?</tt> method is used to determine if the driver can
      # do the work, while the <tt>suitability</tt> method determines if the
      # driver should be automatically selected.
      def suitability(method, *args, &block)
        log.debug("driver #{self.class} doesn't implement the +suitability+ method")
        return -1
      end
    end
  end
end
