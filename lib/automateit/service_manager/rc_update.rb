# == ServiceManager::RC_Update
#
# RC_Update implements the #enabled?, #enable and #disable features of the
# ServiceManager on Gentoo-like systems.
class AutomateIt::ServiceManager::RC_Update < AutomateIt::ServiceManager::SYSV
  # TODO ServiceManager::RC_Update -- implement

  # XXX Commands in the comments are merely hints at how to do this.
  ### depends_on :programs => %w(rc-update)

  def suitability(method, *args) # :nodoc:
    return available? ? 2 : 0
  end

  # See ServiceManager#enabled?
  def enabled?(service)
    _raise_unless_available
    # Do NOT use Gentoo's rc-update because the idiot that wrote that
    # utility truncates service names to look "prettier" and provides no
    # way to disable this annoyance for people that need to query services
    # by name.
    #
    #GENTOO_RUNLEVELS = %w(boot default)
    #! GENTOO_RUNLEVELS.select{|runlevel| File.exists?(File.join("/etc/runlevels", runlevel, service))}.empty?
  end

  # See ServiceManager#enable
  def enable(service, opts={})
    _raise_unless_available
    #system("rc-update add #{service} default")
  end

  # See ServiceManager#disable
  def disable(service, opts={})
    _raise_unless_available
    #system "rc-update del #{service} default"
  end
end
