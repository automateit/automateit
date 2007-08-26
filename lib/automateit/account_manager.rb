module AutomateIt
  # == AccountManager
  #
  # The AccountManager provides a way of managing system accounts, such as UNIX
  # users and groups.
  class AccountManager < Plugin::Manager
    # Find a user account. Method returns a query helper which takes a
    # +username+ as an index argument and returns a Struct::Passwd entry as
    # described in Etc::getpwent if the user exists or a nil if not.
    #
    # Example:
    #   users["root"] # => #<struct Struct::Passwd name="root"...
    #
    #   users["does_not_exist"] # => nil
    def users() dispatch() end

    # Add the +username+ if not already created.
    #
    # Options:
    # * :description - User's full name. Defaults to username.
    # * :home - Path to user's home directory. If not specified, uses system
    #   default like "/home/username".
    # * :create_home - Create homedir. Defaults to true.
    # * :groups - Array of group names to add this user to.
    # * :shell - Path to login shell. If not specified, uses system default
    #   like "/bin/bash".
    # * :uid - Fixnum user ID for user. Default chooses an unused id.
    # * :gid - Fixnum group ID for user. Default chooses same gid as uid.
    #
    # Example:
    #   add_user("bob", :description => "Bob Smith")
    def add_user(username, opts={}) dispatch(username, opts) end

    def update_user(username, opts={}) dispatch(username, opts) end

    # Remove the +username+ if present.
    #
    # Options:
    # * :remove_home - Delete user's home directory and mail spool. Default is
    #   true.
    def remove_user(username, opts={}) dispatch(username, opts) end

    # Is +user+ present?
    def has_user?(user) dispatch(user) end

    # Add +groups+ (array of groupnames) to +user+.
    def add_groups_to_user(groups, user) dispatch(groups, user) end

    # Remove +groups+ (array of groupnames) from +user+.
    def remove_groups_from_user(groups, user) dispatch(groups, user) end

    #.......................................................................

    # Find a group. Method returns a query helper which takes a
    # +groupname+ as an index argument and returns a Struct::Group entry as
    # described in Etc::getgrent if the group exists or a nil if not.
    #
    # Example:
    #   groups["root"] # => #<struct Struct::Group name="root"...
    #
    #   groups["does_not_exist"] # => nil
    def groups() dispatch() end

    # Add +groupname+ if it doesn't exist. Options:
    # * :members - Array of usernames to add as members.
    # * :gid - Group ID to use. Default is to find an unused id.
    def add_group(groupname, opts={}) dispatch(groupname, opts) end

    def update_group(groupname, opts={}) dispatch(groupname, opts) end

    # Remove +groupname+ if it exists.
    def remove_group(groupname, opts={}) dispatch(groupname, opts) end

    # Does +group+ exist?
    def has_group?(group) dispatch(group) end

    # Add +users+ (array of usernames) to +group+.
    def add_users_to_group(users, group) dispatch(users, group) end

    # Remove +users+ (array of usernames) from +group+.
    def remove_users_from_group(users, group) dispatch(users, group) end

    # Array of groupnames this user is a member of.
    def groups_for_user(query) dispatch(query) end

    # Array of usernames in group.
    def users_for_group(query) dispatch(query) end

    # Hash of usernames and the groupnames they're members of.
    def users_to_groups() dispatch() end

    #-----------------------------------------------------------------------

    # == AccountManager::Portable
    #
    # A pure-Ruby, portable driver for the AccountManager. It is only suitable
    # for doing queries and lacks methods such as +add_user+. Platform-specific
    # drivers inherit from this class and provide these methods.
    class Portable < Plugin::Driver
      depends_on :nothing

      def suitability(method, *args)
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
    end # class Portable

    #-----------------------------------------------------------------------

    # == AccountManager::Linux
    #
    # A Linux-specific driver for the AccountManager.
    class Linux < Portable
      depends_on :programs => %w(useradd usermod deluser groupadd groupmod groupdel)

      def suitability(method, *args)
        return available? ? 2 : 0
      end

      def setup(*args)
        super(*args)
        @nscd = interpreter.which("nscd")
      end

      #.......................................................................

      # See AccountManager#add_user
      def add_user(username, opts={})
        return false if has_user?(username)
        cmd = "useradd"
        cmd << " --comment #{opts[:description] || username}"
        cmd << " --home #{opts[:home]}" if opts[:home]
        cmd << " --create-home" unless opts[:create_home] == false
        cmd << " --groups #{opts[:groups].join(' ')}" if opts[:groups]
        cmd << " --shell #{opts[:shell] || "/bin/bash"}"
        cmd << " --uid #{opts[:uid]}" if opts[:uid]
        cmd << " --gid #{opts[:gid]}" if opts[:gid]
        cmd << " #{username} < /dev/null"
        cmd << " > /dev/null" if opts[:quiet]
        # --password CRYPT(3)ENCRYPTED
        # TODO set password
        interpreter.sh(cmd)
        interpreter.sh("nscd --invalidate passwd") if @nscd

        unless opts[:group] == false
          groupname = opts[:group] || username
          unless has_group?(groupname)
            # FIXME gid isn't available because user hasn't been created
            opts = {:members => [username]}
            opts[:gid] = users[username].uid if writing?
            add_group(groupname, opts)
          end
        end

        return users[username]
      end

      # See AccountManager#remove_user
      def remove_user(username, opts={})
        return false unless has_user?(username)
        cmd = "deluser"
        cmd << " --remove-home" unless opts[:remove_home] == false
        cmd << " #{username}"
        cmd << " > /dev/null" if opts[:quiet]
        interpreter.sh(cmd)
        interpreter.sh("nscd --invalidate passwd") if @nscd
        remove_group(username) if has_group?(username)
        return true
      end

      # See AccountManager#add_groups_to_user
      def add_groups_to_user(groups, username)
        groups = [groups].flatten
        present = groups_for_user(username)
        missing = groups - present
        return false if missing.empty?

        cmd = "usermod -a -G #{missing.join(',')} #{username}"
        interpreter.sh(cmd)
        interpreter.sh("nscd --invalidate group") if @nscd
        return missing
      end

      # See AccountManager#remove_groups_from_user
      def remove_groups_from_user(groups, username)
        groups = [groups].flatten
        present = groups_for_user(username)
        removeable = groups & present
        return false if removeable.empty?

        cmd = "usermod -G #{(present-groups).join(',')} #{username}"
        interpreter.sh(cmd)
        interpreter.sh("nscd --invalidate group") if @nscd
        return removeable
      end

      #.......................................................................

      # See AccountManager#add_group
      def add_group(groupname, opts={})
        return false if has_group?(groupname)
        cmd = "groupadd"
        cmd << " -g #{opts[:gid]}" if opts[:gid]
        cmd << " #{groupname}"
        interpreter.sh(cmd)
        interpreter.sh("nscd --invalidate group") if @nscd
        add_users_to_group(opts[:members], groupname) if opts[:members]
        return groups[groupname]
      end

      # See AccountManager#remove_group
      def remove_group(groupname, opts={})
        return false unless has_group?(groupname)
        cmd = "groupdel #{groupname}"
        interpreter.sh(cmd)
        interpreter.sh("nscd --invalidate group") if @nscd
        return true
      end

      # See AccountManager#add_users_to_group
      def add_users_to_group(users, groupname)
        users = [users].flatten
        # FIXME must include pwent.gid
        grent = groups[groupname]
        missing = \
          if writing? and not grent
            raise ArgumentError.new("no such group: #{groupname}")
          elsif writing? or grent
            users - grent.mem
          else
            users
          end
        return false if missing.empty?

        for username in missing
          cmd = "usermod -a -G #{groupname} #{username}"
          interpreter.sh(cmd)
        end
        interpreter.sh("nscd --invalidate group") if @nscd
        return missing
      end

      # See AccountManager#remove_users_from_group
      def remove_users_from_group(users, groupname)
        users = [users].flatten
        grent = groups[groupname]
        present = \
          if writing? and not grent
            raise ArgumentError.new("no such group: #{groupname}")
          elsif writing? or grent
            grent.mem & users
          else
            users
          end
        return false if present.empty?

        u2g = users_to_groups
        for username in present
          user_groups = u2g[username]
          cmd = "usermod -G #{(user_groups.to_a-[groupname]).join(',')} #{username}"
          interpreter.sh(cmd)
        end
        interpreter.sh("nscd --invalidate group") if @nscd
        return present
      end
    end # class Linux
  end # class AccountManager
end # module AutomateIt
