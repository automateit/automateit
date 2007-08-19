require 'automateit'

module AutomateIt
  class Plugin

    class Base < Common
      def setup(opts={})
        super(opts)
        @interpreter ||= opts[:interpreter] || AutomateIt::Interpreter.new(:parent => self)
      end

      def token
        self.class.token
      end

      def self.token
        return to_s.demodulize.underscore.to_sym
      end

      def self.collect_registrations
        cattr_accessor :classes

        self.classes = []

        def self.inherited(subclass)
          classes << subclass unless classes.include?(subclass)
        end

        def self.abstract_plugin
          classes.delete(self) if classes.include?(self)
        end
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

      def default=(token)
        default(token)
      end

      def dispatch(*args, &block)
        # Extract caller's method as symbol to save user from having to specify it
        method = caller[0].match(/:in `(.+?)'/)[1].to_sym
        dispatch_to(method, *args, &block)
      end

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

      def driver_suitability_levels_for(method, *args, &block)
        results = {}
        @drivers.each_pair do |name, driver|
          next unless driver.respond_to?(method)
          results[name] = driver.suitability(method, *args, &block)
        end
        return results
      end

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
    end

    #-----------------------------------------------------------------------

    class Driver < Base
      collect_registrations

      attr_writer :available

      # Is this driver available on this platform? For example, this method is
      # used by the PackageManager driver for APT to determine if the "apt-get"
      # program is installed.
      #
      # The <tt>available?</tt> method is used to determine if the driver can
      # do the work, while the <tt>suitability</tt> method determines if the
      # driver should be automatically selected.
      def available?
        log.debug("driver #{self.class} doesn't implement the +available?+ method")
        return false
      end

      # Provides caching for the <tt>available?</tt> method. Example:
      #   def available?
      #     return _cache_available do
      #       # Put your expensive detection logic here, it'll only be run once
      #       # and the result cached.
      #       true
      #     end
      #   end
      def _cache_available(&block)
        return defined?(@available) ? @available : @available = block.call
      end
      protected :_cache_available

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
