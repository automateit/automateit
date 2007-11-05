# == AccountManager::PasswdPTY
#
# An AccountManager driver for +passwd+ command found on Unix-like systems
# using the Ruby PTY implementation.
#
# *WARNING*: The Ruby PTY module is unreliable or unavailable on most
# platforms. It may hang indefinitely or report incorrect results. Every
# attempt has been made to work around these problems, but this is a low-level
# problem. You are strongly encouraged to install the +expect+ program, which
# works flawlessly. Once the +expect+ program is installed, passwords will be
# changed using the AccountManager::PasswdExpect driver, which works properly.
class ::AutomateIt::AccountManager::PasswdPTY < ::AutomateIt::AccountManager::BaseDriver
  depends_on \
    :programs => %w(passwd uname),
    :libraries => %w(open3 expect pty),
    # Something is horribly wrong with Ruby PTY on Sun
    :callbacks => lambda { `uname -s`.strip !~ /sunos|solaris/i }

  def suitability(method, *args) # :nodoc:
    # Level must be higher than Linux
    return available? ? 3 : 0
  end

  # See AccountManager#passwd
  def passwd(user, password, opts={})
    log.info(PERROR+"Setting password with flaky Ruby PTY, which hangs or fails randomly. Install 'expect' (http://expect.nist.gov/) for reliable operation.")
    _passwd_helper(user, password, opts) do
      log.silence(Logger::WARN) do
        interpreter.mktemp do |filename|
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
      end
    end

  end

  def _passwd_raw(user, password, opts={})
    quiet = (opts[:quiet] or not log.info?)

    require 'open4'
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
