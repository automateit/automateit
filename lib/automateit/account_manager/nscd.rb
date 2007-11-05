# == AccountManager::NSCD
#
# AccountManager driver for invalidating records stored in the NSCD, Name
# Service Cache Daemon, found on Unix-like systems.
class ::AutomateIt::AccountManager::NSCD < ::AutomateIt::AccountManager::BaseDriver
  depends_on :programs => %w(nscd ps),
    # FIXME AccountManager.nscd - "ps -ef" isn't portable, may need to be "ps aux" or such
    :callbacks => lambda{`ps -ef`.match(%r{/usr/sbin/nscd$})}

  def suitability(method, *args) # :nodoc:
    # Level must be higher than Portable
    return available? ? 5 : 0
  end

  # Returns the NSCD database for the specified shorthand +query+.
  def database_for(query)
    case query.to_sym
    when :user, :users, :passwd, :password
      :passwd
    when :group, :groups
      :group
    else
      raise ArgumentError.new("Unknown cache database: #{query}")
    end
  end

  def invalidate(database)
    return false unless available?

    interpreter.sh("nscd -i #{database_for(database)}")
  end
end
