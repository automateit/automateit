# == AccountManager::Passwd
#
# An AccountManager driver for the +passwd+ command found on Unix-like systems.
class ::AutomateIt::AccountManager::Passwd < ::AutomateIt::AccountManager::BaseDriver
  depends_on \
    :programs => %w(passwd),
    :libraries => %w(open3 expect pty)

  def suitability(method, *args) # :nodoc:
    # Level must be higher than Linux
    return available? ? 3 : 0
  end

  # See AccountManager#passwd
  def passwd(user, password, opts={})
    users = interpreter.account_manager.users

    unless users[user]
      if preview?
        log.info(PNOTE+"Setting password for user: #{user}")
        return true
      else
        raise ArgumentError.new("No such user: #{user}")
      end
    end

    case user
    when Symbol: user = user.to_s
    when Integer: user = users[user]
    when String: # leave it alone
    else raise TypeError.new("Unknown user type: #{user.class}")
    end

    tries = 5
    exitstatus = nil
    begin
      exitstruct = _passwd_raw(user, password, opts)
      if exitstatus and not exitstruct.exitstatus.zero?
        # FIXME AccountManager::Linux#passwd -- The `passwd` command randomly returns exit status 10 even when it succeeds. What does this mean and how to deal with it?! Temporary workaround is to throw an error and force a retry.
        raise Errno::EPIPE.new("bad exitstatus %s" % exitstruct.exitstatus)
      end
    rescue Errno::EPIPE => e
      # FIXME AccountManager::Linux#passwd -- EPIPE exception randomly thrown even when `passwd` succeeds. How to eliminate it? How to differentiate between this false error and a real one?
      if tries <= 0
        raise e
      else
        tries -= 1
        retry
      end
    end

    return exitstruct.exitstatus.zero?
  end

  def _passwd_raw(user, password, opts={})
    quiet = (opts[:quiet] or not log.info?)

    return Open4::popen4("passwd %s 2>&1" % user) do |pid, sin, sout, serr|
      $expect_verbose = ! quiet
      2.times do
        sout.expect(/:/)
        sleep 0.1 # Reduce chance of passwd thinking we're a robot :(
        sin.puts password
        puts "*" * 12 unless quiet
      end
    end
  end
  protected :_passwd_raw
end
