# == AccountManager::NSCD
#
# AccountManager driver for invalidating records stored in the NSCD, Name
# Service Cache Daemon, found on Unix-like systems.
class ::AutomateIt::AccountManager::NSCD < ::AutomateIt::AccountManager::BaseDriver
  depends_on :programs => %w(nscd ps), 
    :callbacks => [lambda{`ps -ef`.match(%r{/usr/sbin/nscd$})}]

  def suitability(method, *args) # :nodoc:
    # Level must be higher than Portable
    return available? ? 5 : 0
  end

  def invalidate(database)
    return false unless available?

    name = \
      case database.to_sym
      when :user, :users, :passwd
        :passwd
      when :group, :groups
        :group
      else
        raise ArgumentError.new("Unknown cache database: #{database}")
      end
    interpreter.sh("nscd -i #{name}")
  end
end
