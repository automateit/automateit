module AutomateIt
  class ServiceManager
    # == Chkconfig
    #
    # The Chkconfig driver implements the ServiceManager methods for #enabled?,
    # #enable and #disable on RedHat-like platforms. It uses the SYSV driver
    # for handling the methods #running?, #start and #stop.
    class Chkconfig < SYSV
      depends_on :programs => %w(chkconfig)

      def suitability(method, *args) # :nodoc:
        return available? ? 2 : 0
      end

      # See ServiceManager#enabled?
      def enabled?(service)
        _raise_unless_available
        # "chkconfig --list service" may produce output like the below:
        # service httpd supports chkconfig, but is not referenced in any runlevel (run 'chkconfig --add automateit_service_sysv_test')
        # => httpd           0:off   1:off   2:off   3:off   4:off   5:off   6:off
        if matcher = `chkconfig --list #{service} < /dev/null 2>&1` \
            .match(/^(#{service}).+?(\d+:(on|off).+?)$/)
          return true if matcher[2].match(/\b\d+:on\b/)
        end
        return false
      end

      # See ServiceManager#enable
      def enable(service, opts={})
        _raise_unless_available
        return false if enabled?(service)
        interpreter.sh("chkconfig --add #{service}")
      end

      # See ServiceManager#disable
      def disable(service, opts={})
        _raise_unless_available
        return false unless enabled?(service)
        interpreter.sh("chkconfig --del #{service}")
      end
    end
  end
end
