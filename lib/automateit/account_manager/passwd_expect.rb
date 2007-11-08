# == AccountManager::PasswdExpect
#
# An AccountManager driver for the +passwd+ command found on Unix-like systems
# using the +expect+ program as a wrapper because the Ruby PTY implementation
# is unreliable.
class ::AutomateIt::AccountManager::PasswdExpect < ::AutomateIt::AccountManager::BaseDriver
  depends_on :programs => %w(passwd expect)

  def suitability(method, *args) # :nodoc:
    # Level must be higher than PasswdPTY
    return available? ? 9 : 0
  end

  # See AccountManager#passwd
  def passwd(user, password, opts={})
    _passwd_helper(user, password, opts) do |user, password, opts|
      log.silence(Logger::WARN) do
        interpreter.mktemp do |filename|
          # Script derived from /usr/share/doc/expect/examples/autopasswd
          interpreter.render(:text => <<-HERE, :to => filename)
set password "#{password}"
spawn passwd "#{user}"
expect "assword:"
sleep 0.1
send "$password\\r"
expect "assword:"
sleep 0.1
send "$password\\r"
expect eof
          HERE

          cmd = "expect #{filename}"
          cmd << " > /dev/null" if opts[:quiet]
          return(interpreter.sh cmd)
        end
      end
    end
  end
end

