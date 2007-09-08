# == ServiceManager::UpdateRCD
#
# The UpdateRCD driver implements the ServiceManager methods for #enabled?,
# #enable and #disable on Debian-like platforms. It uses the SYSV driver
# for handling the methods #running?, #start and #stop.
class AutomateIt::ServiceManager::UpdateRCD < AutomateIt::ServiceManager::SYSV
  TOOL = "update-rc.d"

  depends_on :programs => [TOOL]

  def suitability(method, *args) # :nodoc:
    return available? ? 3 : 0
  end

  # See ServiceManager#enable
  def enable(service, opts={})
    _raise_unless_available
    return false if enabled?(service)
    interpreter.sh("#{TOOL} #{service} defaults < /dev/null > /dev/null")
  end

  # See ServiceManager#disable
  def disable(service, opts={})
    _raise_unless_available
    return false unless enabled?(service)
    interpreter.sh("#{TOOL} -f #{service} remove < /dev/null > /dev/null")
  end

  def enabled?(service, opts={})
    _raise_unless_available
    cmd = "#{TOOL} -n -f #{service} remove < /dev/null"
    output = `#{cmd}`
    return ! output.match(/etc\/rc[\dS].d|Nothing to do\./).nil?
  end
end
