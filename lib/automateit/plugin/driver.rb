module AutomateIt
  class Plugin
    # == Plugin::Driver
    #
    # A driver provides the low-level functionality for features, e.g., the
    # PackageManager::APT driver is responsible for installing a software
    # package using the Debian <tt>apt-get</tt> command. Multiple drivers
    # providing common functionality are managed by a single Manager class,
    # e.g., drivers that install software packages are managed by the
    # PackageManager.
    #
    # A driver may only be available on certain platforms and provides its
    # manager with an idea of when it's suitable. For example, if a platform
    # doesn't have the <tt>apt-get</tt> command, the PackageManager::APT driver
    # must tell the PackageManager class that it's not suitable.
    #
    # === Writing your own drivers
    #
    # To write a driver, find the most similar driver available for a specific
    # plugin, copy it, and rework its code. Save the code for the new driver in
    # a file ending with .rb into the project’s +lib+ directory, it will be
    # automatically loaded whenever the Interpreter for that project is run.
    # Please test and contribute drivers so that others can benefit.
    #
    # IMPORTANT GOTCHA: You must prefix the AutomateIt module name with a "::"!
    #
    # Here's a minimalistic PackageManager that can be dropped into +lib+:
    #
    #   class MyDriver < ::AutomateIt::PackageManager::BaseDriver
    #     depends_on :nothing
    #
    #     def suitability(method, *args) # :nodoc:
    #       # Never select as default driver
    #       return 0
    #     end
    #   end
    class Driver < Base
      # Driver classes. Represented as a hash of manager tokens to arrays of
      # their driver classes, for example:
      #
      #  { :package_manager => [
      #                          AutomateIt::PackageManager::APT,
      #                          AutomateIt::PackageManager::YUM,
      #                          ...
      cattr_accessor :classes
      self.classes = {}

      # Retrieve the manager token for this driver
      def self.manager_token
        fragments = base_driver.to_s.split(/::/)
        return fragments[fragments.size-2].underscore.to_sym
      end

      BASE_DRIVER_NAME = "BaseDriver"

      # Is this a base driver?
      def self.base_driver?
        to_s =~ /::#{BASE_DRIVER_NAME}/
      end

      # Retrieve the base driver class for this driver.
      def self.base_driver
        ancestors.select{|t| t.to_s =~ /::#{BASE_DRIVER_NAME}/}.last
      end

      # Register drivers. Concrete drivers are added to a class-wide data
      # structure which maps them to the manager they belong to.
      def self.inherited(subclass) # :nodoc:
        base_driver = subclass.base_driver
        if subclass.base_driver?
          # Ignore, base drivers should never be registered
        elsif base_driver
          manager = subclass.manager_token
          classes[manager] ||= []
          classes[manager] << subclass unless classes[manager].include?(subclass)
          ### puts "manager %s / driver %s" % [manager, subclass]
        else
          # XXX Should this really raise an exception?
          raise TypeError.new("Can't determine manager for driver: #{subclass}")
        end
      end

      # Declare that this driver class is abstract. It can be subclassed but
      # will not be instantiated by the Interpreter's Managers. BaseDriver
      # classes are automatically declared abstract.
      def self.abstract_driver
        if base_driver?
          # Ignore, base drivers should never have been registered
        elsif manager = manager_token
          classes[manager].delete(self)
        else
          raise TypeError.new("Can't find manager for abstract plugin: #{self}")
        end
      end

      # Defines resources this driver depends on.
      #
      # Options:
      # * :files -- Array of filenames that must exist.
      # * :directories -- Array of directories that must exist.
      # * :programs -- Array of programs, checked with +which+, that must exist.
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
      # by #depends_on to make sure that they're all present, otherwise raises
      # a NotImplementedError. If a driver author needs to do some other kind
      # of check, it's reasonable to override this method.
      #
      # For example, this method is used by the PackageManager driver for APT
      # to determine if the "apt-get" program is installed.
      #
      # What's the difference between #available? and #suitability? The
      # #available? method is used to determine if the driver *can* do the
      # work, while the #suitability method determines if the driver *should*
      # be automatically selected.
      def available?
        # Some drivers don't run +depends_on+, so assume they're available.
        return true unless self.class.respond_to?(:_depends_on_opts)
        opts = self.class._depends_on_opts

        # Driver said that it +depends_on :nothing+, so it's available.
        return true if opts == :nothing

        is_available = self.class._is_available
        if is_available.nil? and opts.nil?
          #log.debug(PNOTE+"don't know if driver #{self.class} is available, maybe it doesn't state what it +depends_on+")
          return false
        elsif is_available.nil?
          all_present = true
          missing = {}
          for kind in [:files, :directories, :programs, :callbacks]
            next unless opts[kind]
            for item in [opts[kind]].flatten
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
                  rescue ArgumentError, NotImplementedError, NoMethodError
                    false
                  end
                when :callbacks
                  item.call() ? true : false
                else
                  raise "unknown kind: #{kind}"
                end
              unless present
                all_present = false
                missing[kind] ||= []
                missing[kind] << item
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
      # #available?.
      def _raise_unless_available
        unless available?
          msg = ""
          for kind, elements in self.class._missing_dependencies
            msg << "; " unless msg == ""
            msg << "%s: %s" % [kind, elements.sort.join(', ')]
          end
          raise NotImplementedError.new("Missing dependencies -- %s" % msg)
        end
      end

      # What is this driver's suitability for automatic detection? The Manager
      # queries its drivers when there isn't a driver specified with a
      # <tt>:with</tt> or #default so it can choose a suitable driver for the
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
