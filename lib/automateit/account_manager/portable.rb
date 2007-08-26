module AutomateIt
  class AccountManager
    # == AccountManager::Portable
    #
    # A pure-Ruby, portable driver for the AccountManager. It is only suitable
    # for doing queries and lacks methods such as +add_user+. Platform-specific
    # drivers inherit from this class and provide these methods.
    class Portable < Plugin::Driver
      depends_on :nothing

      def suitability(method, *args) # :nodoc:
        return 1
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
        return [] if noop? and not pwent
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
        return (noop? || ! grent) ? [] : grent.mem
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
          result[pwent.name] ||= Set.new
          result[pwent.name] << grent.name
        end
        return result
      end
    end
  end
end
