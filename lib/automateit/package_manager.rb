module AutomateIt
  class PackageManager < Plugin::Manager
    # Are these +packages+ installed? Returns +true+ if all +packages+ are
    # installed, or an array of installed packages when called with an options
    # hash that contains <tt>:list => true</tt>
    def installed?(*packages) dispatch(*packages) end

    # Are these +packages+ not installed? Returns +true+ if none of these
    # +packages+ are installed, or a array of packages that aren't installed
    # when called with an options hash that contains <tt>:list => true</tt>
    def not_installed?(*packages) dispatch(*packages) end

    # Install these +packages+. Returns +true+ if install succeeded; or
    # +false+ if all packages were already installed.
    def install(*packages) dispatch(*packages) end

    # Uninstall these +packages+. Returns +true+ if uninstall succeeded; or
    # +false+ if none of the packages were installed.
    def uninstall(*packages) dispatch(*packages) end

    #-----------------------------------------------------------------------

    # The Base module makes it easier to write PackageManager drivers. It can't
    # install packages itself, but its helper methods make it easier for other
    # drivers to do this by providing them with a bunch of common functionality
    # that would otherwise have to be duplicated in each driver. These helpers
    # are generic enough to be useful for all sorts of PackageManager driver
    # implementations. Read the APT driver for good usage examples.
    module Base
      protected

      # Are these +packages+ installed? Works like PackageManager#installed?
      # but calls a block that actually checks whether the packages are
      # installed and returns an array of packages installed.
      #
      # For example:
      #   _installed_helper?("package1", "package2", :list => true) do |packages, opts|
      #     # Dummy code which reports that these packages are installed:
      #     ["package1]
      #   end
      def _installed_helper?(*packages, &block) # :yields: filtered_packages, opts
        packages, opts = args_and_opts(*packages)
        packages = [packages].flatten
        available = block.call(packages, opts)
        result = opts[:list] ? available : (packages - available).empty?
        log.debug("installed? result %s / packages %s / available %s" % [result.inspect, packages.inspect, available.inspect])
        return result
      end

      # Are these +packages+ not installed?
      def _not_installed_helper?(*packages)
        # Requires that your PackageManager#installed? method is implemented.
        packages, opts = args_and_opts(*packages)
        packages = [packages].flatten
        available = [installed?(packages, :list => true)].flatten
        missing = packages - available

        result = opts[:list] ? missing : (packages - missing).empty?
        log.debug("not_installed? result %s / packages %s / missing %s" % [result.inspect, packages.inspect, missing.inspect])
        return result
      end

      # Install these +packages+. Works like PackageManager#install but calls a
      # block that's responsible for actually installing the packages and
      # returning true if the installation succeeded. This block is only called
      # if packages need to be installed and receives a filtered list of
      # packages that are guaranteed not to be installed on the system already.
      #
      # For example:
      #   _install_helper("package1", "package2", :quiet => true) do |packages, opts|
      #     # Dummy code that installs packages here, e.g:
      #     system("apt-get", "install", "-y", packages)
      #   end
      def _install_helper(*packages, &block) # :yields: filtered_packages, opts
        packages, opts = args_and_opts(*packages)
        packages = [packages].flatten

        missing = not_installed?(packages, :list => true)
        return false if missing.blank?
        return true if noop?

        # XXX Ignore return value?
        block.call(missing, opts)
        unless (failed = not_installed?(missing, :list => true)).empty?
          # FIXME spec failure
          raise ArgumentError.new("couldn't install: #{failed.join(' ')}")
        else
          return true
        end
      end

      # Uninstall these +packages+. Works like PackageManager#uninstall but calls a
      # block that's responsible for actually uninstalling the packages and
      # returning true if the uninstall succeeded. This block is only called
      # if packages need to be uninstalled and receives a filtered list of
      # packages that are guaranteed to be installed on the system.
      #
      # For example:
      #   _uninstall_helper("package1", "package2", :quiet => true) do |packages, opts|
      #     # Dummy code that removes packages here, e.g:
      #     system("apt-get", "remove", "-y", packages)
      #   end
      def _uninstall_helper(*packages, &block) # :yields: filtered_packages, opts
        packages, opts = args_and_opts(*packages)
        packages = [packages].flatten

        present = installed?(packages, :list => true)
        return false if present.blank?
        return true if noop?

        # XXX Ignore return value?
        block.call(present, opts)
        unless (failed = installed?(present, :list => true)).empty?
          # FIXME spec failure
          raise ArgumentError.new("couldn't uninstall: #{failed.join(' ')}")
        else
          return true
        end
      end
    end

    #-----------------------------------------------------------------------

    # The APT driver for the PackageManager provides a way to manage software
    # packages on Debian-style systems using +apt-get+ and +dpkg+.
    class APT < Plugin::Driver
      include Base

      def available?
        return _cache_available do
          interpreter.instance_eval{which("apt-get") && which("dpkg")}
        end
      end

      def suitability(method, *args)
        return available? ? 1 : 0
      end

      # See AutomateIt::PackageManager#installed?
      def installed?(*packages)
        return _installed_helper?(*packages) do |list, opts|
          ### data = `dpkg --status nomarch apache2 not_a_real_package 2>&1`
          cmd = "dpkg --status"
          list.each{|package| cmd << " "+package}
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
      def not_installed?(*packages)
        return _not_installed_helper?(*packages)
      end

      # See AutomateIt::PackageManager#install
      def install(*packages)
        return _install_helper(*packages) do |list, opts|
          # apt-get options:
          # -y : yes to all queries
          # -q : no interactive progress bars
          cmd = "apt-get install -y -q"
          list.each{|package| cmd << " "+package}
          cmd << " < /dev/null"
          cmd << " > /dev/null" if opts[:quiet]
          cmd << " 2>&1"

          interpreter.sh(cmd)
        end
      end

      # See AutomateIt::PackageManager#uninstall
      def uninstall(*packages)
        return _uninstall_helper(*packages) do |list, opts|
          # apt-get options:
          # -y : yes to all queries
          # -q : no interactive progress bars
          cmd = "apt-get remove -y -q"
          list.each{|package| cmd << " "+package}
          cmd << " < /dev/null"
          cmd << " > /dev/null" if opts[:quiet]
          cmd << " 2>&1"

          interpreter.sh(cmd)
        end
      end
    end

    #-----------------------------------------------------------------------

    # The YUM driver for the PackageManager provides a way to manage software
    # packages on Red Hat-style systems using +yum= and +rpm+.
    class YUM < Plugin::Driver
      include Base

      def available?
         return _cache_available do
           interpreter.instance_eval{which("yum") && which("rpm")}
         end
      end

      def suitability(method, *args)
        return available? ? 1 : 0
      end

      # See AutomateIt::PackageManager#installed?
      def installed?(*packages)
        return _installed_helper?(*packages) do |list, opts|
          ### rpm -q --nosignature --nodigest --qf "%{NAME} # %{VERSION} # %{RELEASE}\n" httpd nomarch foo
          cmd = 'rpm -q --nosignature --nodigest --qf "%{NAME} # %{VERSION} # %{RELEASE}\n"'
          list.each{|package| cmd << " "+package}
          cmd << " 2>&1" # missing packages are listed on STDERR
          log.debug("$$$ "+cmd)
          data = `#{cmd}`

          matches = data.scan(/^(.+) # (.+) # .+$/)
          available = matches.inject([]) do |sum, match|
            package, status = match
            sum << package
            sum
          end

          log.debug("### installed?(%s) => %s" % [list.inspect, available.inspect])
          available
        end
      end

      # See AutomateIt::PackageManager#not_installed?
      def not_installed?(*packages)
        _not_installed_helper?(*packages)
      end

      # See AutomateIt::PackageManager#install
      def install(*packages)
        return _install_helper(*packages) do |list, opts|
          # yum options:
          # -y : yes to queries
          # -d 0 : no debugging info
          # -e 0 : show only fatal errors
          # -C : don't download headers
          cmd = "yum -y -d 0 -e 0 -C install"
          list.each{|package| cmd << " "+package}
          cmd << " < /dev/null"
          cmd << " > /dev/null" if opts[:quiet]
          cmd << " 2>&1"

          interpreter.sh(cmd)
        end
      end

      # See AutomateIt::PackageManager#uninstall
      def uninstall(*packages)
        return _uninstall_helper(*packages) do |list, opts|
          cmd = "rpm --erase --quiet"
          list.each{|package| cmd << " "+package}
          cmd << " < /dev/null"
          cmd << " > /dev/null" if opts[:quiet]
          cmd << " 2>&1"

          interpreter.sh(cmd)
        end
      end
    end
  end
end
