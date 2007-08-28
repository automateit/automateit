module AutomateIt
  class ServiceManager
    # == ServiceManager::Sysvconfig
    #
    # The Sysvconfig driver implements the ServiceManager methods for #enable
    # and #disable on Debian-like platforms. It uses the SYSV driver for
    # handling the methods #enabled?, #running?, #start and #stop.
    #
    # This driver does not implement the #enabled? method because the
    # underlying "sysvconfig" program is slow enough that it's better to rely
    # on the SYSV driver's simpler but much faster implementation.
    class Sysvconfig < SYSV
      # TODO ServiceManager::Sysconfig -- Debian systems don't have 'sysvconfig' package installed by default, how to enable/disable services there?
      depends_on :programs => %w(sysvconfig)

      def suitability(method, *args) # :nodoc:
        return available? ? 2 : 0
      end

=begin
      def enabled?(service)
        # TODO ServiceManager::Sysconfig#enabled? -- Allow user to request this disabled method which is more correct but very slow
        #
        # "sysconfig --listlinks" output looks like this, note how there's no
        # space between the name and run-level when displaying a long name:
        #   nfs-kernel-server   K80 K80 S20 S20 S20 S20 K80
        #   automateit_service_sysv_testK20 K20 S20 S20 S20 S20 K20
        _raise_unless_available
        if matcher = `sysvconfig --listlinks` \
            .match(/^(#{service})((\s|[KS]\d{2}\b).+?)$/)
          return true if matcher[2].match(/\bS\d{2}\b/)
        end
        return false
      end
=end

      # See ServiceManager#enable
      def enable(service, opts={})
        _raise_unless_available
        return false if enabled?(service)
        interpreter.sh("sysvconfig --enable #{service} < /dev/null > /dev/null")
      end

      # See ServiceManager#disable
      def disable(service, opts={})
        _raise_unless_available
        return false unless enabled?(service)
        interpreter.sh("sysvconfig --disable #{service} < /dev/null > /dev/null")
      end
    end
  end
end
