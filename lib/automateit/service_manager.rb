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

      def _run_command(command, opts={})
        command_text = command.is_a?(String) ? command : command.join(' ')
        log.send((opts[:quiet] || opts[:checking]) ? :debug : :info,
          "$$$ #{command_text}")
        Open4.popen4(*command) do |pid, sin, sout, serr|
          print serr.read rescue IOError unless opts[:checking]
          print sout.read rescue IOError unless opts[:quiet] or opts[:checking]
        end
        return $?.exitstatus.zero?
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

    # TODO implement
    class Sysvconfig < SYSV
      def suitability(method, *args)
        @suitable ||= ! interpreter.which("sysvconfig").nil?
        return @suitable ? 2 : 0
      end

      def enabled?(service)
        #! `</dev/null sysvconfig --listlinks| egrep "\\b#{service}\\b"`.chomp.match(/\bS\d+\b/).nil?
      end

      def enable(service, opts={})
        #system "</dev/null sysvconfig --enable #{service}"
      end

      def disable(service, opts={})
        #system "</dev/null sysvconfig --disable #{service}"
      end
    end

    # TODO implement
    class RC_Update < SYSV
      def suitability(method, *args)
        @suitable ||= ! interpreter.which("rc-update").nil?
        return @suitable ? 2 : 0
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

    # TODO implement
    class Chkconfig < SYSV
      def suitability(method, *args)
        @suitable ||= ! interpreter.which("chkconfig").nil?
        return @suitable ? 2 : 0
      end

      def enabled?(service)
        # chkconfig --list service
        # => httpd           0:off   1:off   2:off   3:off   4:off   5:off   6:off
      end

      def enable(service, opts={})
        # chkconfig --add service
      end

      def disable(service, opts={})
        # chkconfig --del service
      end
    end
  end
end
