require 'automateit'

module AutomateIt
  # ServiceManager provides a way of managing services, such as UNIX daemons.
  class ServiceManager < Plugin::Manager
    # Is this +service+ running?
    def running?(service) dispatch(service) end

    # Start this +service+ if it's not running.
    def start(service, opts={}) dispatch(service, opts) end

    # Stop this +service+ if it's running.
    def stop(service, opts={}) dispatch(service, opts) end

    # Will this +service+ start when the computer is rebooted?
    def enabled?(service) dispatch(service) end

    # Make this +service+ start when the computer is rebooted, but only if it's
    # not already enabled.
    def enable(service, opts={}) dispatch(service, opts) end

    # Don't make this +service+ start when the computer is rebooted, but only
    # if it's already enabled.
    def disable(service, opts={}) dispatch(service, opts) end

    # The SYSV driver implements the ServiceManager methods for #running?,
    # #start and #stop on UNIX-like platforms that use the System V init
    # process using a <tt>/etc/init.d</tt> directory.
    #
    # It also implements a basic #enabled? method that's very fast but may not
    # work correctly on all SysV platforms. This method should be overridden by
    # more specific drivers when reasonable.
    #
    # It does not implement the #enable and #disable methods because these are
    # not standardized and must be implemented using platform-specific drivers,
    # e.g. Chkconfig on RedHat-like platforms.
    class SYSV < Plugin::Driver
      ETC_INITD = "/etc/init.d"
      def suitability(method, *args)
        return File.directory?(ETC_INITD) ? 1 : 0
      end

      def _run_command(args, opts={})
        cmd = String === args ? args : args.map{|t|'"%s"'%t}.join(' ')
        if opts[:checking]
          cmd += " > /dev/null 2>&1" # Discard STDOUT and STDERR
        elsif opts[:quiet]
          cmd += " > /dev/null" # Discard only STDOUT
        end

        log.send((opts[:quiet] || opts[:checking]) ? :debug : :info, "$$$ #{cmd}")
        if writing?
          system(cmd)
          return $?.exitstatus.zero?
        else
          false
        end
      end
      private :_run_command

      def _run_service(service, action, opts={})
        return _run_command(["#{ETC_INITD}/#{service}", action.to_s], opts)
      end
      private :_run_service

      def running?(service)
        return _run_service(service, :status, :checking => true)
      end

      def start(service, opts={})
        return false if not opts[:force] and running?(service)
        return _run_service(service, :start, opts)
      end

      def stop(service, opts={})
        return false if not opts[:force] and not running?(service)
        return _run_service(service, :stop, opts)
      end

      def enabled?(service)
        return ! Dir["/etc/rc*.d/*"].grep(/\/S\d{2}#{service}$/).empty?
      end
    end

    # The Sysvconfig driver implements the ServiceManager methods for #enable
    # and #disable on Debian-like platforms. It uses the SYSV driver for
    # handling the methods #enabled?, #running?, #start and #stop.
    #
    # This driver does not implement the #enabled? method because the
    # underlying "sysvconfig" program is slow enough that it's better to rely
    # on the SYSV driver's simpler but much faster implementation.
    class Sysvconfig < SYSV
      def suitability(method, *args)
        return @suitable ||= interpreter.which("sysvconfig").nil? ? 0 : 2
      end

=begin
      def enabled?(service)
        # TODO Allow user to request the wrapped version of this method if they
        # want correctness rather than speed?
        #
        # "sysconfig --listlinks" output looks like this, note how there's no
        # space between the name and run-level when displaying a long name:
        #   nfs-kernel-server   K80 K80 S20 S20 S20 S20 K80
        #   automateit_service_sysv_testK20 K20 S20 S20 S20 S20 K20
        if matcher = `sysvconfig --listlinks` \
            .match(/^(#{service})((\s|[KS]\d{2}\b).+?)$/)
          return true if matcher[2].match(/\bS\d{2}\b/)
        end
        return false
      end
=end

      def enable(service, opts={})
        return false if enabled?(service)
        interpreter.sh("sysvconfig --enable #{service} < /dev/null > /dev/null")
      end

      def disable(service, opts={})
        return false unless enabled?(service)
        interpreter.sh("sysvconfig --disable #{service} < /dev/null > /dev/null")
      end
    end

    # The Chkconfig driver implements the ServiceManager methods for #enabled?,
    # #enable and #disable on RedHat-like platforms. It uses the SYSV driver
    # for handling the methods #running?, #start and #stop.
    class Chkconfig < SYSV
      def suitability(method, *args)
        return @suitable ||= interpreter.which("chkconfig").nil? ? 0 : 2
      end

      def enabled?(service)
        # "chkconfig --list service" may produce output like the below:
        # service httpd supports chkconfig, but is not referenced in any runlevel (run 'chkconfig --add automateit_service_sysv_test')
        # => httpd           0:off   1:off   2:off   3:off   4:off   5:off   6:off
        if matcher = `chkconfig --list #{service} < /dev/null 2>&1` \
            .match(/^(#{service}).+?(\d+:(on|off).+?)$/)
          return true if matcher[2].match(/\b\d+:on\b/)
        end
        return false
      end

      def enable(service, opts={})
        return false if enabled?(service)
        interpreter.sh("chkconfig --add #{service}")
      end

      def disable(service, opts={})
        return false unless enabled?(service)
        interpreter.sh("chkconfig --del #{service}")
      end
    end

=begin
    # RC_Update implements the #enabled?, #enable and #disable features of the
    # ServiceManager on Gentoo-like systems.
    #--
    # TODO implement
    class RC_Update < SYSV
      def suitability(method, *args)
        return @suitable ||= (interpreter.which("rc-update").nil? ? 0 : 2)
      end

      def enabled?(service)
        # Do NOT use Gentoo's rc-update because the idiot that wrote that
        # utility truncates service names to look "prettier" and provides no
        # way to disable this annoyance for people that need to query services
        # by name.
        #
        #GENTOO_RUNLEVELS = %w(boot default)
        #! GENTOO_RUNLEVELS.select{|runlevel| File.exists?(File.join("/etc/runlevels", runlevel, service))}.empty?
      end

      def enable(service, opts={})
        #system("rc-update add #{service} default")
      end

      def disable(service, opts={})
        #system "rc-update del #{service} default"
      end
    end
=end
  end
end
