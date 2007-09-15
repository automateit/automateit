# == ServiceManager
#
# ServiceManager provides a way of managing services, such starting and
# stopping Unix daemons.
class AutomateIt::ServiceManager < AutomateIt::Plugin::Manager
  # Is this +service+ started?
  #
  # Options:
  # * :wait -- Maximum number of seconds to wait until service starts. Useful
  #   when a service accepts a #start and returns immediately before the service
  #   has finished starting.
  def started?(service, opts={}) dispatch(service, opts) end

  # Is this +service+ stopped?
  #
  # Options:
  # * :wait -- Maximum number of seconds to wait until service stops. Useful
  #   when a service accepts a #stop and returns immediately while the service
  #   continues running for a few seconds.
  def stopped?(service, opts={}) dispatch(service, opts) end

  # Alias for #started?
  def running?(service, opts={}) dispatch_to(:started?, service, opts) end

  # Start this +service+ if it's not running.
  def start(service, opts={}) dispatch(service, opts) end

  # Stop this +service+ if it's running.
  def stop(service, opts={}) dispatch(service, opts) end

  # Restart this +service+ if it's running, or start it if it's stopped.
  def restart(service, opts={}) dispatch(service, opts) end

  # If +is_restart+, #restart the service, otherwise #start it. 
  #
  # Example:
  #  modified = edit "/etc/myapp.conf" {#...}
  #  service_manager.start_or_restart("myapp", modified)
  def start_or_restart(service, is_restart, opts={}) dispatch(service, is_restart, opts) end

  # Start and enable the service using #start and #enable.
  def start_and_enable(service, opts={}) dispatch(service, opts) end

  # Tell the +service+ to take a specific +action+, e.g., "condrestart".
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

# == ServiceManager::BaseDriver
#
# Base class for all ServiceManager drivers.
class AutomateIt::ServiceManager::BaseDriver < AutomateIt::Plugin::Driver
  # See ServiceManager#start_or_restart
  def start_or_restart(service, is_restart, opts={})
    send(is_restart ? :restart : :start, service, opts)
  end

  # See ServiceManager#start_and_enable
  def start_and_enable(service, opts={})
    start(service, opts)
    enable(service, opts)
  end
end

# Drivers
require 'automateit/service_manager/sysv'
require 'automateit/service_manager/update_rcd'
require 'automateit/service_manager/chkconfig'
require 'automateit/service_manager/rc_update'
