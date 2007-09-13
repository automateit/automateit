# == ServiceManager::RC_Update
#
# RC_Update implements the #enabled?, #enable and #disable features of the
# ServiceManager on Gentoo-like systems.
class AutomateIt::ServiceManager::RC_Update < AutomateIt::ServiceManager::SYSV
  depends_on :programs => %w(rc-update)

  def suitability(method, *args) # :nodoc:
    return available? ? 2 : 0
  end

  # See ServiceManager#enabled?
  def enabled?(service)
    _raise_unless_available
    # Do NOT use Gentoo's rc-update because the idiot that wrote that utility
    # truncates service names to look "prettier" and provides no way to disable
    # this annoyance for people that need to query services by name.
    result = %w(boot default).select do |runlevel|
      File.exists?(File.join("/etc/runlevels", runlevel, service))
    end
    return ! result.empty?
  end

  # See ServiceManager#enable
  def enable(service, opts={})
    _raise_unless_available
    return false if enabled?(service)
    interpreter.sh("rc-update add #{service} default > /dev/null 2>&1")
  end

  # See ServiceManager#disable
  def disable(service, opts={})
    _raise_unless_available
    return false unless enabled?(service)
    interpreter.sh("rc-update del #{service} default > /dev/null 2>&1")
  end
end
