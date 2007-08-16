module AutomateIt
  class PackageManager < Plugin::Manager
    def installed?(*args) dispatch(*args) end
    def not_installed?(*args) dispatch(*args) end
    def install(*args) dispatch(*args) end
    def uninstall(*args) dispatch(*args) end

    #-----------------------------------------------------------------------

    # The Base module makes it easier to write PackageManager drivers. Although
    # it can't install packages itself, its helper methods make it easier for
    # other drivers to do this by providing them with a bunch of common
    # functionality that would otherwise have to be duplicated in each driver.
    # These helpers are written in a very generic way and should provide value
    # for all sorts of PackageManager driver implementations. Read the APT
    # driver for a good usage examples.
    module Base
      protected

      # Are these packages installed? Arguments array:
      # * +callback+ - Proc that accepts an array of +packages+ and hash of
      #   +opts+, and returns an array of packages that are installed.
      # * +packages+ - Array of packages to check.
      # * +opts+ - Hash of options.
      #
      # Returns +true+ if all +packages+ are installed, or a list of installed
      # packages when called with +opts+ :list => true
      def _installed_helper?(*a)
        args, opts = args_and_opts(*a)
        callback, packages = args
        packages = [packages].flatten
        available = callback.call(packages, opts)
        result = opts[:list] ? available : (packages - available).empty?
        log.debug("installed? result %s / packages %s / available %s" % [result.inspect, packages.inspect, available.inspect])
        return result
      end

      # Are these packages not installed? Arguments array:
      # * +callback+ - Proc that accepts an array of +packages+ and hash of
      #   +opts+, and returns an array of packages that are not installed.
      # * +packages+ - Array of packages to check.
      # * +opts+ - Hash of options.
      #
      # Returns +true+ if all +packages+ are not installed, or a list of not
      # installed packages when called with +opts+ :list => true
      def _not_installed_helper?(*a)
        packages, opts = args_and_opts(*a)
        packages.flatten!
        available = [installed?(packages, :list => true)].flatten
        missing = packages - available

        result = opts[:list] ? missing : (packages - missing).empty?
        log.debug("not_installed? result %s / packages %s / missing %s" % [result.inspect, packages.inspect, missing.inspect])
        return result
      end

      # Install these packages. Arguments array:
      # * +callback+ - Proc that accepts an array of +packages+ and hash of
      #   +opts+ and installs them.
      # * +packages+ - Array of packages to install.
      # * +opts+ - Hash of optsions.
      #
      # Returns boolean from callback indicating a successful installation.
      def _install_helper(*a)
        args, opts = args_and_opts(*a)
        callback, packages = args
        packages = [packages].flatten

        missing = not_installed?(packages, :list => true)
        return false if ! missing || (missing.is_a?(Array) && missing.empty?)
        return callback.call(missing, opts)
      end

      # Uninstall these packages. Arguments array:
      # * +callback+ - Proc that accepts an array of +packages+ and hash of
      #   +opts+ and uninstalls them.
      # * +packages+ - Array of packages to uninstall.
      # * +opts+ - Hash of optsions.
      #
      # Returns boolean from callback indicating a successful uninstall.
      def _uninstall_helper(*a)
        args, opts = args_and_opts(*a)
        callback, packages = args
        packages = [packages].flatten

        present = installed?(packages, :list => true)
        return false if ! present || (present.is_a?(Array) && present.empty?)
        return callback.call(present, opts)
      end
    end

    #-----------------------------------------------------------------------

    class APT < Plugin::Driver
      include Base

      def suitability(method, *args)
        return @suitability ||= interpreter.which("apt-get").nil? ? 0 : 1
      end

      def installed?(*a)
        callback = lambda do |packages, opts|
          ### data = `dpkg --status nomarch apache2 not_a_real_package 2>&1`
          cmd = "dpkg --status"
          packages.each{|package| cmd << " "+package}
          cmd << " 2>&1" # missing packages are listed on STDERR
          log.debug("$$$ "+cmd)
          data = `#{cmd}`

          matches = data.scan(/^Package: (.+)$\s*^Status: (.+)$/)
          available = matches.inject([]) do |sum, match|
            package, status = match
            sum << package if status.match(/(?:^|\s)installed\b/)
            sum
          end

          available
        end
        return _installed_helper?(callback, *a)
      end

      def not_installed?(*a)
        return _not_installed_helper?(*a)
      end

      def install(*a)
        callback = lambda do |packages, opts|
          # apt-get options:
          # -y : yes to all queries
          # -q : no interactive progress bars
          cmd = "apt-get install -y -q"
          packages.each{|package| cmd << " "+package}
          cmd << " < /dev/null"
          cmd << " > /dev/null" if opts[:quiet]
          cmd << " 2>&1"

          interpreter.sh(cmd)
        end
        return _install_helper(callback, *a)
      end

      def uninstall(*a)
        callback = lambda do |packages, opts|
          # apt-get options:
          # -y : yes to all queries
          # -q : no interactive progress bars
          cmd = "apt-get remove -y -q"
          packages.each{|package| cmd << " "+package}
          cmd << " < /dev/null"
          cmd << " > /dev/null" if opts[:quiet]
          cmd << " 2>&1"

          interpreter.sh(cmd)
        end
        return _uninstall_helper(callback, *a)
      end
    end
  end
end
