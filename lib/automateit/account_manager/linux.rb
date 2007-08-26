module AutomateIt
  class AccountManager
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
    end
  end
end
