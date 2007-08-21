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
      # by +depends_on+ to make sure that they're all present, otherwise throws
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
        is_available = self.class._is_available
        opts = self.class._depends_on_opts
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
                  # FIXME How do +which+ when interpreter queries availability, which causes an infinite loop? Temporary hack is to bypass the check.
                  ### when :programs: ! interpreter.which(item).nil?
                  ! interpreter.shell_manager[:posix].which(item).nil?
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
