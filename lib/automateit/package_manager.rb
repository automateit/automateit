module AutomateIt
  class PackageManager < Plugin::Manager
    def installed?(*args) dispatch(*args) end
    def not_installed?(*args) dispatch(*args) end
    def install(*args) dispatch(*args) end
    def uninstall(*args) dispatch(*args) end

    class APT < Plugin::Driver
      def suitability(method, *args)
        return @suitability ||= interpreter.which("apt-get").nil? ? 0 : 1
      end

      def installed?(*a)
        packages, opts = args_and_opts(*a)
        packages.flatten!

        cmd = "dpkg --status"
        packages.each{|package| cmd << " "+package}
        cmd << " 2>&1" # missing packages are listed on STDERR
        log.debug("$$$ "+cmd)
        data = `#{cmd}`
        ### data = `dpkg --status nomarch apache2 not_a_real_package 2>&1`

        matches = data.scan(/^Package: (.+)$\s*^Status: (.+)$/)
        available = matches.inject([]) do |sum, match|
          package, status = match
          sum << package if status.match(/(?:^|\s)installed\b/)
          sum
        end

        result = opts[:list] ? available : (packages - available).empty?
        log.debug("installed? result %s / packages %s / available %s" % [result.inspect, packages.inspect, available.inspect])
        return result
      end

      def not_installed?(*a)
        packages, opts = args_and_opts(*a)
        packages.flatten!
        available = [installed?(packages, :list => true)].flatten
        missing = packages - available

        result = opts[:list] ? missing : (packages - missing).empty?
        log.debug("not_installed? result %s / packages %s / missing %s" % [result.inspect, packages.inspect, missing.inspect])
        return result
      end

      def install(*a)
        packages, opts = args_and_opts(*a)
        packages.flatten!
        missing = not_installed?(packages, :list => true)
        return false if ! missing || (missing.is_a?(Array) && missing.empty?)

        # apt-get options:
        # -y : yes to all queries
        # -q : no interactive progress bars
        cmd = "apt-get install -y -q"
        missing.each{|package| cmd << " "+package}
        cmd << " < /dev/null"
        cmd << " > /dev/null" if opts[:quiet]
        cmd << " 2>&1"

        return writing? ? interpreter.sh(cmd) : true
      end

      def uninstall(*a)
        packages, opts = args_and_opts(*a)
        packages.flatten!
        present = installed?(packages, :list => true)
        return false if ! present || (present.is_a?(Array) && present.empty?)

        # apt-get options:
        # -y : yes to all queries
        # -q : no interactive progress bars
        cmd = "apt-get remove -y -q"
        present.each{|package| cmd << " "+package}
        cmd << " < /dev/null"
        cmd << " > /dev/null" if opts[:quiet]
        cmd << " 2>&1"

        return writing? ? interpreter.sh(cmd) : true
      end
    end
  end
end
