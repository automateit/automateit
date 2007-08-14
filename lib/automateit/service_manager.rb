require 'automateit'

module AutomateIt
  class ServiceManager < Plugin::Manager
    def running?(service) dispatch(service) end
    def start(service, opts={}) dispatch(service, opts) end
    def stop(service, opts={}) dispatch(service, opts) end

    def enabled?(service) dispatch(service) end
    def enable(service, opts={}) dispatch(service, opts) end
    def disable(service, opts={}) dispatch(service, opts) end

    class SYSV < Plugin::Driver
      ETC_INITD = "/etc/init.d"
      def suitability(method, *args)
        return File.directory?(ETC_INITD) ? 1 : 0
      end

      def _run_command(args, opts={})
        cmd = args.is_a?(String) ? args : args.map{|t|'"%s"'%t}.join(' ')
        if opts[:checking]
          cmd += " > /dev/null 2>&1" # Discard STDOUT and STDERR
        elsif opts[:quiet]
          cmd += " > /dev/null" # Discard only STDOUT
        end

        log.send((opts[:quiet] || opts[:checking]) ? :debug : :info, "$$$ #{cmd}")
        if interpreter.writing?
          system(cmd)
          return $?.exitstatus.zero?
        else
          false
        end
      end

      def _run_service(service, action, opts={})
        return _run_command(["#{ETC_INITD}/#{service}", action.to_s], opts)
      end

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
    end

    # Sysvconfig implements the enable/disable/enabled? features of the
    # ServiceManager on Debian-like systems.
    class Sysvconfig < SYSV
      def suitability(method, *args)
        return @suitable ||= (interpreter.which("sysvconfig").nil? ? 0 : 2)
      end

      def enabled?(service)
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

      def enable(service, opts={})
        interpreter.sh("sysvconfig --enable #{service} < /dev/null > /dev/null")
      end

      def disable(service, opts={})
        interpreter.sh("sysvconfig --disable #{service} < /dev/null > /dev/null")
      end
    end

    # RC_Update implements the enable/disable/enabled? features of the
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

    # Chkconfig implements the enable/disable/enabled? features of the
    # ServiceManager on RedHat-like systems.
    class Chkconfig < SYSV
      def suitability(method, *args)
        return @suitable ||= (interpreter.which("chkconfig").nil? ? 0 : 2)
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
        interpreter.sh("chkconfig --add #{service}")
      end

      def disable(service, opts={})
        interpreter.sh("chkconfig --del #{service}")
      end
    end
  end
end
