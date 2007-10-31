# == AccountManager::Etc
#
# An AccountManager driver for Unix-like OSes that have the Ruby Etc module. It
# is only suitable for doing queries and lacks methods that perform
# modifications, such as +add_user+. Platform-specific drivers inherit from
# this class and provide methods that perform modifications.
class ::AutomateIt::AccountManager::Etc< ::AutomateIt::AccountManager::BaseDriver
  depends_on :callbacks => [lambda{AutomateIt::AccountManager::Etc.has_etc?}]

  def suitability(method, *args) # :nodoc:
    return 1
  end
  
  # Does this platform provide a way of querying users and groups through 
  # the 'etc' module?
  def self.has_etc?
    begin
      require './spec/integration/account_manager_spec.rb:1etc'
      return defined?(Etc)
    rescue LoadError
      return false
    end
  end
  
  # Alias for AccountManager::Etc.has_etc?
  def has_etc?
    self.has_etc?
  end

  #.......................................................................

  # == UserQuery
  #
  # A class used for querying users. See AccountManager#users.
  class UserQuery
    # See AccountManager#users
    def [](query)
      Etc.endpwent
      begin
        case query
        when String
          return Etc.getpwnam(query)
        when Fixnum
          return Etc.getpwuid(query)
        else
          raise TypeError.new("unknonwn type for query: #{query.class}")
        end
      rescue ArgumentError
        return nil
      end
    end
  end

  # See AccountManager#users
  def users
    return UserQuery.new
  end

  # See AccountManager#has_user?
  def has_user?(query)
    return ! users[query].nil?
  end

  #.......................................................................

  # == GroupQuery
  #
  # A class used for querying groups. See AccountManager#groups.
  class GroupQuery
    # See AccountManager#groups
    def [](query)
      Etc.endgrent
      begin
        case query
        when String
          return Etc.getgrnam(query)
        when Fixnum
          return Etc.getgrgid(query)
        else
          raise TypeError.new("unknonwn type for query: #{query.class}")
        end
      rescue ArgumentError
        return nil
      end
    end
  end

  # See AccountManager#groups
  def groups
    return GroupQuery.new
  end

  # See AccountManager#has_group?
  def has_group?(query)
    return ! groups[query].nil?
  end

  # See AccountManager#groups_for_user
  def groups_for_user(query)
    pwent = users[query]
    return [] if preview? and not pwent
    username = pwent.name
    result = Set.new
    result << groups[pwent.gid].name if groups[pwent.gid]
    Etc.group do |grent|
      result << grent.name if grent.mem.include?(username)
    end
    return result.to_a
  end

  # See AccountManager#users_for_group
  def users_for_group(query)
    grent = groups[query]
    return (preview? || ! grent) ? [] : grent.mem
  end

  # See AccountManager#users_to_groups
  def users_to_groups
    result = {}
    Etc.group do |grent|
      grent.mem.each do |username|
        result[username] ||= Set.new
        result[username] << grent.name
      end
    end
    Etc.passwd do |pwent|
      grent = groups[pwent.gid]
      unless grent
        log.fatal(PNOTE+"WARNING: User's default group doesn't exist: user %s, gid %s" % [pwent.name, pwent.gid])
        next
      end
      result[pwent.name] ||= Set.new
      result[pwent.name] << grent.name
    end
    return result
  end
end
