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
        _raise_unless_available

        packages, opts = args_and_opts(*packages)
        packages = [packages].flatten
        available = block.call(packages, opts)
        truth = (packages - available).empty?
        result = opts[:list] ? available : truth
        log.debug(PNOTE+"installed?(#{packages.inspect}) => #{truth}: #{available.inspect}")
        return result
      end

      # Are these +packages+ not installed?
      def _not_installed_helper?(*packages)
        _raise_unless_available

        # Requires that your PackageManager#installed? method is implemented.
        packages, opts = args_and_opts(*packages)
        packages = [packages].flatten
        available = [installed?(packages, :list => true)].flatten
        missing = packages - available
        truth = (packages - missing).empty?
        result = opts[:list] ? missing : truth
        log.debug(PNOTE+"not_installed?(#{packages.inspect}) => #{truth}: #{missing.inspect}")
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
        _raise_unless_available

        packages, opts = args_and_opts(*packages)
        packages = [packages].flatten

        missing = not_installed?(packages, :list => true)
        return false if missing.blank?
        block.call(missing, opts)
        return true if noop?
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
        _raise_unless_available

        packages, opts = args_and_opts(*packages)
        packages = [packages].flatten

        present = installed?(packages, :list => true)
        return false if present.blank?
        block.call(present, opts)
        return true if noop?
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

      depends_on :programs => %w(apt-get dpkg)

      def suitability(method, *args)
        return available? ? 1 : 0
      end

      # See AutomateIt::PackageManager#installed?
      def installed?(*packages)
        return _installed_helper?(*packages) do |list, opts|
          ### data = `dpkg --status nomarch apache2 not_a_real_package 2>&1`
          cmd = "dpkg --status "+list.join(" ")+" 2>&1"

          log.debug(PEXEC+cmd)
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
          cmd = "apt-get install -y -q "+list.join(" ")+" < /dev/null"
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
          cmd = "apt-get remove -y -q "+list.join(" ")+" < /dev/null"
          cmd << " > /dev/null" if opts[:quiet]
          cmd << " 2>&1"

          interpreter.sh(cmd)
        end
      end
    end

    #-----------------------------------------------------------------------

    # The YUM driver for the PackageManager provides a way to manage software
    # packages on Red Hat-style systems using +yum+ and +rpm+.
    class YUM < Plugin::Driver
      include Base

      depends_on :programs => %w(yum rpm)

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

          log.debug(PEXEC+cmd)
          data = `#{cmd}`
          matches = data.scan(/^(.+) # (.+) # .+$/)
          available = matches.inject([]) do |sum, match|
            package, status = match
            sum << package
            sum
          end
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
          cmd = "yum -y -d 0 -e 0"
          cmd << " -C" if opts[:cache] == true
          cmd << " install "+list.join(" ")+" < /dev/null"
          cmd << " > /dev/null" if opts[:quiet]
          cmd << " 2>&1"

          interpreter.sh(cmd)
        end
      end

      # See AutomateIt::PackageManager#uninstall
      def uninstall(*packages)
        return _uninstall_helper(*packages) do |list, opts|
          cmd = "rpm --erase --quiet "+list.join(" ")+" < /dev/null"
          cmd << " > /dev/null" if opts[:quiet]
          cmd << " 2>&1"

          interpreter.sh(cmd)
        end
      end
    end

    #-----------------------------------------------------------------------

    # The GEM driver for the PackageManager provides a way to manage software
    # packages for RubyGems using the +gem+ command.
    class Gem < Plugin::Driver
      include Base

      depends_on :programs => %w(gem)

      def suitability(method, *args)
        # Never select GEM as the default driver
        return 0
      end

      def installed?(*packages)
        return _installed_helper?(*packages) do |list, opts|
          # Sample session:
          #   No match found for s33r (> 0)
          #   Gem activesupport-1.4.2
          #
          #   Gem net-ssh-1.1.2
          #     needle (>= 1.2.0)
          cmd = "gem dependency "+list.join(" ")+" 2>&1"

          log.debug(PEXEC+cmd)
          data = `#{cmd}`

          # Gem lists packages out of order, which screws up the
          # install/uninstall sequence, so we need to put them back in the
          # order that the user specified.
          present = data.scan(/^Gem (.+)-.+?$/).flatten
          available = []
          for package in list
            available << package if present.include?(package)
          end
          available
        end
      end

      def not_installed?(*packages)
        _not_installed_helper?(*packages)
      end

      def install(*packages)
        return _install_helper(*packages) do |list, opts|
          # Why is the "gem" utility such a steaming pile of offal? Problems include:
          # - Requires interactive input to install a package
          # - Repeatedly updates indexes even when there's no reason to and can't be told to stop
          # - Doesn't cache packages, insists on downloading them again
          # - Installs broken packages, often without giving any indication of failure
          # - Installs broken packages and leaves you to deal with the jagged pieces
          # - Sometimes fails through exit status, sometimes through output, but not consistently
          # - Lacks a proper "is this package installed?" feature
          # - A nightmare to deal with if you want to install your own GEMHOME/GEMPATH

          # Example of an invalid gem that'll cause the failure I'm trying to avoid below:
          #   package_manager.install("sys-cpu", :with => :gem)

          # gem options:
          # -y : Include dependencies,
          # -E : use /usr/bin/env for installed executables; but only with >= 0.9.4
          cmd = "gem install -y"
          cmd << " --no-ri" if opts[:ri] == false or opts[:docs] == false
          cmd << " --no-rdoc" if opts[:rdoc] == false or opts[:docs] == false
          cmd << " "+list.join(" ")+" 2>&1"

          # XXX Try to warn the user that they won't see any output for a while
          log.info(PNOTE+"Installing Gems, this will take a while...") if writing? and not opts[:quiet]
          log.info(PEXEC+cmd)
          return true if noop?

          uninstall_needed = false
          begin
            exitstruct = Open4::popen4(cmd) do |pid, sin, sout, serr|
              $expect_verbose = opts[:quiet] ? false : true

              re_missing=/Could not find.+in any repository/m
              re_select=/Select which gem to install.+>/m
              re_failed=/Gem files will remain.+for inspection/m
              re_all=/#{re_missing}|#{re_select}|#{re_failed}/m

              while true
                begin
                  captureded = sout.expect(re_all)
                rescue NoMethodError
                  log.debug(PNOTE+"Gem seems to be done")
                  break
                end
                ### puts "Captureded %s" % captureded.inspect
                captured = captureded.first
                if captured.match(re_failed)
                  log.warn(PNOTE+"Gem install failed mid-process")
                  uninstall_needed = true
                  break
                elsif captured.match(re_select)
                  choice = captured.match(/^ (\d+)\. .+?\(ruby\)\s*$/)[1]
                  log.info(PNOTE+"Guessing: #{choice}")
                  sin.puts(choice)
                end
              end
            end
          rescue Errno::ENOENT => e
            raise NotImplementedError.new("can't find gem command: #{e}")
          rescue Errno::EIO => e
            # End of content reached through alternative means
          end

          if uninstall_needed or not exitstruct.exitstatus.zero?
            log.error(PERROR+"Gem install failed, trying to uninstall broken pieces: #{list.inspect}")
            uninstall(list, opts)

            raise ArgumentError.new("Gem install failed, either it's invalid or missing a dependency: #{list.inspect}")
          end
        end
      end

      def uninstall(*packages)
        return _uninstall_helper(*packages) do |list, opts|
          # FIXME idiotic program MAY prompt you like this on uninstall:
=begin
root@ubuntu:/mnt/satori/svnwork/automateit/src/examples/myapp_rails# gem uninstall mongrel

Select RubyGem to uninstall:
 1. mongrel-1.0.1
 2. mongrel_cluster-1.0.2
 3. All versions
> 3

You have requested to uninstall the gem:
        mongrel-1.0.1
mongrel_cluster-1.0.2 depends on [mongrel (>= 1.0.1)]
If you remove this gems, one or more dependencies will not be met.
Continue with Uninstall? [Yn]  y
Successfully uninstalled mongrel version 1.0.1
Successfully uninstalled mongrel_cluster version 1.0.2
Remove executables and scripts for
'mongrel_cluster_ctl' in addition to the gem? [Yn]  y
Removing mongrel_cluster_ctl
root@ubuntu:/mnt/satori/svnwork/automateit/src/examples/myapp_rails#
=end
          for package in list
            # gem options:
            # -x : remove installed executables
            cmd = "gem uninstall -x #{package} < /dev/null"
            cmd << " > /dev/null" if opts[:quiet]
            cmd << " 2>&1"
            interpreter.sh(cmd)
          end
        end
      end
    end

    #-----------------------------------------------------------------------

    # The Egg driver for the PackageManager provides a way to manage
    # Python software packages with the PEAK +easy_install+ tool.
    class Egg < Plugin::Driver
      include Base

      depends_on :programs => %w(python easy_install)

      def suitability(method, *args)
        # Never select as default driver
        return 0
      end

      # See AutomateIt::PackageManager#installed?
      def installed?(*packages)
        return _installed_helper?(*packages) do |list, opts|
          cmd = "python -c 'import sys; print(sys.path)' 2>&1"

          log.debug(PEXEC+cmd)
          data = `#{cmd}`
          # Extract array elements, turn them into basenames, and then split on
          # '-' because that's the separator for the name and version.
          found = data.scan(/'([^']+\.egg)'/).flatten.map{|t| File.basename(t).split('-', 2)[0]}
          available = found & list
        end
      end

      # See AutomateIt::PackageManager#not_installed?
      def not_installed?(*packages)
        return _not_installed_helper?(*packages)
      end

      # See AutomateIt::PackageManager#install
      def install(*packages)
        return _install_helper(*packages) do |list, opts|
          # easy_install options:
          # -Z : install into a direcory rather than a file
          cmd = "easy_install -Z "+list.join(" ")+" < /dev/null"
          cmd << " > /dev/null" if opts[:quiet]
          cmd << " 2>&1"

          interpreter.sh(cmd)
        end
      end

      # See AutomateIt::PackageManager#uninstall
      def uninstall(*packages)
        return _uninstall_helper(*packages) do |list, opts|
          # easy_install options:
          # -m : removes package from the easy-install.pth
          cmd = "easy_install -m "+list.join(" ")+" < /dev/null"
          cmd << " > /dev/null" if opts[:quiet]
          cmd << " 2>&1"

          # Parse output for paths and remove the orphaned entries
          log.info(PEXEC+cmd)
          return packages if noop?
          data = `#{cmd}`
          paths = data.scan(/^Using ([^\n]+\.egg)$/m).flatten
          for path in paths
            interpreter.rm_rf(path)
          end
        end
      end
    end
  end
end
