module AutomateIt
  # == ServiceManager
  #
  # ServiceManager provides a way of managing services, such starting and
  # stopping UNIX daemons.
  class ServiceManager < Plugin::Manager
    require 'automateit/service_manager/sysv'
    require 'automateit/service_manager/sysvconfig'
    require 'automateit/service_manager/chkconfig'
    require 'automateit/service_manager/rc_update'

    # Is this +service+ running?
    def running?(service) dispatch(service) end

    # Start this +service+ if it's not running.
    def start(service, opts={}) dispatch(service, opts) end

    # Stop this +service+ if it's running.
    def stop(service, opts={}) dispatch(service, opts) end

    # Restart this +service+ if it's running, or start it if it's stopped.
    def restart(service, opts={}) dispatch(service, opts) end

    # Tell the +service+ to take a specific +action+, e.g. "condrestart".
    def tell(service, action, opts={}) dispatch(service, action, opts={}) end

    # Will this +service+ start when the computer is rebooted?
    def enabled?(service) dispatch(service) end

    # Make this +service+ start when the computer is rebooted, but only if it's
    # not already enabled.
    def enable(service, opts={}) dispatch(service, opts) end

    # Don't make this +service+ start when the computer is rebooted, but only
    # if it's already enabled.
    def disable(service, opts={}) dispatch(service, opts) end
  end
end
