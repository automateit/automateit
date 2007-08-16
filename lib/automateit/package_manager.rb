module AutomateIt
  class PackageManager < Plugin::Manager
    # Are these packages installed?
    #
    # Arguments array:
    # * +packages+ - Array of packages to check.
    # * +opts+ - Hash of options.
    #
    # Returns +true+ if all +packages+ are installed, or a array of installed
    # packages when called with +opts+ :list => true
    def installed?(*args) dispatch(*args) end

    # Are these packages not installed?
    #
    # Arguments array:
    # * +packages+ - Array of packages to check.
    # * +opts+ - Hash of options.
    #
    # Returns +true+ if all +packages+ are not installed, or a array of not
    # installed packages when called with +opts+ :list => true
    def not_installed?(*args) dispatch(*args) end

    # Install these packages.
    #
    # Arguments array:
    # * +packages+ - Array of packages to install.
    # * +opts+ - Hash of options.
    #
    # Returns boolean from callback indicating a successful installation. If
    # all packages are already installed, will return false without taking any
    # action.
    def install(*args) dispatch(*args) end

    # Uninstall these packages.
    #
    # Arguments array:
    # * +packages+ - Array of packages to uninstall.
    # * +opts+ - Hash of options.
    #
    # Returns boolean from callback indicating a successful uninstall. If none
    # of the packages are installed, will return false without taking any
    # action.
    def uninstall(*args) dispatch(*args) end

    #-----------------------------------------------------------------------

    # The Base module makes it easier to write PackageManager drivers. Although
    # it can't install packages itself, its helper methods make it easier for
    # other drivers to do this by providing them with a bunch of common
    # functionality that would otherwise have to be duplicated in each driver.
    # These helpers are written to be generic enough to be useful for all sorts
    # of PackageManager driver implementations. Read the APT driver for a good
    # usage examples.
    module Base
      protected

      # Are these packages installed? Works just like PackageManager#installed?
      # but calls a block that actually checks whether the packages are
      # installed and returns an array of packages installed.
      #
      # For example:
      #   _installed_helper?("package1", "package2", :list => true) do |packages, opts|
      #     # Dummy code which reports that these packages are installed:
      #     ["package1]
      #   end
      def _installed_helper?(*a, &block) # :yields: packages, opts
        packages, opts = args_and_opts(*a)
        packages = [packages].flatten
        available = block.call(packages, opts)
        result = opts[:list] ? available : (packages - available).empty?
        log.debug("installed? result %s / packages %s / available %s" % [result.inspect, packages.inspect, available.inspect])
        return result
      end

      # Are these packages not installed? Works just like
      # PackageManager#not_installed? but requires that your
      # PackageManager#installed? method is implemented.
      def _not_installed_helper?(*a)
        packages, opts = args_and_opts(*a)
        packages = [packages].flatten
        available = [installed?(packages, :list => true)].flatten
        missing = packages - available

        result = opts[:list] ? missing : (packages - missing).empty?
        log.debug("not_installed? result %s / packages %s / missing %s" % [result.inspect, packages.inspect, missing.inspect])
        return result
      end

      # Install these packages. Works just like PackageManager#install but
      # calls a block that actually installs the packages and returns a boolean
      # success value. The block is guaranteed to get only packages that aren't
      # already installed.
      #
      # For example:
      #   _install_helper("package1", "package2", :quiet => true) do |packages, opts|
      #     # Dummy code that installs packages here, e.g:
      #     system("apt-get", "install", "-y", packages)
      #   end
      def _install_helper(*a, &block)
        packages, opts = args_and_opts(*a)
        packages = [packages].flatten

        missing = not_installed?(packages, :list => true)
        return false if ! missing || (missing.is_a?(Array) && missing.empty?)
        return block.call(missing, opts)
      end

      # Uninstall these packages. Works just like PackageManager#uninstall but
      # calls a block that actually installs the packages and returns a boolean
      # success value. The block is guaranteed to get only packages that are
      # installed.
      #
      # For example:
      #   _uninstall_helper("package1", "package2", :quiet => true) do |packages, opts|
      #     # Dummy code that removes packages here, e.g:
      #     system("apt-get", "remove", "-y", packages)
      #   end
      def _uninstall_helper(*a, &block)
        packages, opts = args_and_opts(*a)
        packages = [packages].flatten

        present = installed?(packages, :list => true)
        return false if ! present || (present.is_a?(Array) && present.empty?)
        return block.call(present, opts)
      end
    end

    #-----------------------------------------------------------------------

    # The APT driver for the PackageManager provides a way to install software
    # on Debian-like systems using "apt-get" and "dpkg".
    class APT < Plugin::Driver
      include Base

      def suitability(method, *args)
        return @suitability ||= interpreter.instance_eval{which("apt-get") && which("dpkg")} ? 1 : 0
      end

      # See AutomateIt::PackageManager#installed?
      def installed?(*a)
        return _installed_helper?(*a) do |packages, opts|
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
      end

      # See AutomateIt::PackageManager#not_installed?
      def not_installed?(*a)
        return _not_installed_helper?(*a)
      end

      # See AutomateIt::PackageManager#install
      def install(*a)
        return _install_helper(*a) do |packages, opts|
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
      end

      # See AutomateIt::PackageManager#uninstall
      def uninstall(*a)
        return _uninstall_helper(*a) do |packages, opts|
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
      end
    end

    #-----------------------------------------------------------------------

    # The YUM driver for the PackageManager provides a way to install software
    # on RedHat-like systems using "yum" and "rpm".
    class YUM < Plugin::Driver
      include Base

      def suitability(method, *args)
        return @suitability ||= interpreter.instance_eval{which("yum") && which("rpm")} ? 1 : 0
      end

      # See AutomateIt::PackageManager#installed?
      def installed?(*a)
        return _installed_helper?(*a) do |packages, opts|
          ### rpm -q --nosignature --nodigest --qf "%{NAME} # %{VERSION} # %{RELEASE}\n" httpd nomarch foo
          cmd = 'rpm -q --nosignature --nodigest --qf "%{NAME} # %{VERSION} # %{RELEASE}\n"'
          packages.each{|package| cmd << " "+package}
          cmd << " 2>&1" # missing packages are listed on STDERR
          log.debug("$$$ "+cmd)
          data = `#{cmd}`

          matches = data.scan(/^(.+) # (.+) # .+$/)
          available = matches.inject([]) do |sum, match|
            package, status = match
            sum << package
            sum
          end

          log.debug("### installed?(%s) => %s" % [packages.inspect, available.inspect])
          available
        end
      end

      # See AutomateIt::PackageManager#not_installed?
      def not_installed?(*a)
        _not_installed_helper?(*a)
      end

      # See AutomateIt::PackageManager#install
      def install(*a)
        return _install_helper(*a) do |packages, opts|
          # yum options:
          # -y : yes to queries
          # -d 0 : no debugging info
          # -e 0 : show only fatal errors
          # -C : don't download headers
          cmd = "yum -y -d 0 -e 0 -C install"
          packages.each{|package| cmd << " "+package}
          cmd << " < /dev/null"
          cmd << " > /dev/null" if opts[:quiet]
          cmd << " 2>&1"

          interpreter.sh(cmd)
        end
      end

      # See AutomateIt::PackageManager#uninstall
      def uninstall(*a)
        return _uninstall_helper(*a) do |packages, opts|
          cmd = "rpm --erase --quiet"
          packages.each{|package| cmd << " "+package}
          cmd << " < /dev/null"
          cmd << " > /dev/null" if opts[:quiet]
          cmd << " 2>&1"

          interpreter.sh(cmd)
        end
      end
    end
  end
end
