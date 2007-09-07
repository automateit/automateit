module AutomateIt
  class ServiceManager
    # == ServiceManager::SYSV
    #
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
    # e.g., Chkconfig on RedHat-like platforms.
    class SYSV < Plugin::Driver
      ETC_INITD = "/etc/init.d"

      depends_on :directories => [ETC_INITD]

      def suitability(method, *args) # :nodoc:
        return 0 if %w(enabled? enable disable).include?(method.to_s)
        return available? ? 1 : 0
      end

      def _run_command(args, opts={})
        _raise_unless_available
        cmd = String === args ? args : args.join(' ')
        if opts[:checking]
          cmd += " > /dev/null 2>&1" # Discard STDOUT and STDERR
        elsif opts[:quiet]
          cmd += " > /dev/null" # Discard only STDOUT
        end

        log.send((opts[:quiet] || opts[:checking]) ? :debug : :info, PEXEC+cmd)
        if writing? or opts[:checking]
          system(cmd)
          return $?.exitstatus.zero?
        else
          false
        end
      end
      private :_run_command

      # See ServiceManager#tell
      def tell(service, action, opts={})
        return _run_command(["#{ETC_INITD}/#{service}", action.to_s], opts)
      end

      # See ServiceManager#running?
      def running?(service)
        return tell(service, :status, :checking => true)
      end

      # See ServiceManager#start
      def start(service, opts={})
        return false if not opts[:force] and running?(service)
        return tell(service, :start, opts)
      end

      # See ServiceManager#stop
      def stop(service, opts={})
        return false if not opts[:force] and not running?(service)
        return tell(service, :stop, opts)
      end

      # See ServiceManager#restart
      def restart(service, opts={})
        stop(service, opts) if running?(service)
        return start(service, opts)
      end

      # See ServiceManager#enabled?
      def enabled?(service)
        return ! Dir["/etc/rc*.d/*"].grep(/\/S\d{2}#{service}$/).empty?
      end
    end
  end
end
