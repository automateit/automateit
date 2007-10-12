# == ServiceManager::SYSV
#
# The SYSV driver implements the ServiceManager methods for #running?,
# #start and #stop on Unix-like platforms that use the System V init
# process using a <tt>/etc/init.d</tt> directory.
#
# It also implements a basic #enabled? method that's very fast but may not
# work correctly on all SysV platforms. This method should be overridden by
# more specific drivers when reasonable.
#
# It does not implement the #enable and #disable methods because these are
# not standardized and must be implemented using platform-specific drivers,
# e.g., Chkconfig on RedHat-like platforms.
class AutomateIt::ServiceManager::SYSV < AutomateIt::ServiceManager::BaseDriver
  ETC_INITD = "/etc/init.d"

  depends_on :directories => [ETC_INITD]

  def suitability(method, *args) # :nodoc:
    return 0 if %w(enabled? enable disable).include?(method.to_s)
    return available? ? 1 : 0
  end

  def _run_command(args, opts={})
    _raise_unless_available
    cmd = String === args ? args : args.join(' ')
    if opts[:silent] or opts[:check]
      cmd += " > /dev/null 2>&1" # Discard STDOUT and STDERR
    elsif opts[:quiet]
      cmd += " > /dev/null" # Discard only STDOUT
    end

    level = (opts[:quiet] || opts[:silent] || opts[:check]) ? :debug : :info
    log.send(level, PEXEC+cmd)
    if writing? or opts[:check]
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
  def running?(service, opts={})
    return started?(service, opts)
  end

  def _started_and_stopped_helper(kind, service, opts={})
    expected = \
      case kind
      when :started?: true
      when :stopped?: false
      else raise ArgumentError.new("unknown kind argument: #{kind}")
      end

    result = tell(service, :status, :check => true)
    nitpick("_sash top: k=%s r=%s e=%s" % [kind, result, expected])
    return result if expected == result
    if opts[:wait]
      timeout = Time.now + opts[:wait]
      while timeout > Time.now
        log.info(PNOTE+" ServiceManager#%s waiting on '%s' for %0.1f more seconds" %
          [kind, service, timeout - Time.now])
        sleep 0.5
        result = tell(service, :status, :check => true)
        nitpick("_sash rep: k=%s r=%s e=%s" % [kind, result, expected])
        break if expected == result
      end
      log.info(PNOTE+" ServiceManager#%s finished waiting for '%s', got: %s" %
        [kind, service, result])
    end
    return result
  end
  protected :_started_and_stopped_helper

  # See ServiceManager#started?
  def started?(service, opts={})
    return _started_and_stopped_helper(:started?, service, opts)
  end

  # See ServiceManager#stopped?
  def stopped?(service, opts={})
    return ! _started_and_stopped_helper(:stopped?, service, opts)
  end

  # See ServiceManager#start
  def start(service, opts={})
    if not opts[:force] and started?(service, :wait => opts[:wait])
      # Already started
      return false
    else
      # Needs starting or forced
      tell(service, :start, opts)
      return true
    end
  end

  # See ServiceManager#stop
  def stop(service, opts={})
    if not opts[:force] and stopped?(service, :wait => opts[:wait])
      # Already stopped
      return false
    else
      # Needs stopping or forced
      tell(service, :stop, opts)
      return true
    end
  end

  # See ServiceManager#restart
  def restart(service, opts={})
    if started?(service, :wait => opts[:pause])
      # We're certain that service is started
      stop_opts = opts.clone
      stop_opts[:force] = true # Don't check again
      stop(service, stop_opts)
    end

    # We're certain that service is stopped
    start_opts = opts.clone
    start_opts[:force] = true # Don't check again
    return start(service, start_opts)
  end

  # See ServiceManager#enabled?
  def enabled?(service)
    return ! Dir["/etc/rc*.d/*"].grep(/\/S\d{2}#{service}$/).empty?
  end
end
