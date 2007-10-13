# == AccountManager::SunOS
#
# A SunOS-specific driver for the AccountManager.
class ::AutomateIt::AccountManager::SunOS < ::AutomateIt::AccountManager::Portable
  def self.token
    :sunos
  end

  depends_on \
    :programs => %w(uname useradd usermod userdel groupadd groupmod groupdel),
    :callbacks => [lambda{
      `uname -s`.match(/sunos/i) && AutomateIt::AccountManager::Portable.has_etc?
    }]

  def suitability(method, *args) # :nodoc:
    # Level must be higher than Portable
    return available? ? 2 : 0
  end

  #.......................................................................

  # See AccountManager#add_user
  def add_user(username, opts={})
    return _add_user_helper(username, opts) do |username, opts|
=begin
      # FIXME move this to ::BaseDriver
      # TODO: How to efficiently find unused UID/GID? SunOS useradd doesn't check if the GID is available, and because it tries adding at UID 100, it's almost certain to fail because there are system groups at that level. Morons.
      unless opts[:uid] and opts[:gid]
        for i in 1000..60000
          if users[i].nil? and groups[i].nil?
            opts[:uid] = i
            break
          end
        end

        raise IndexError.new("Can't find unused UID/GID") unless opts[:uid]
      end
=end

      cmd = "useradd"
      cmd << " -c #{opts[:description] || username}"
      cmd << " -d #{opts[:home]}" if opts[:home]
      # TODO -m fails on SunOS if auto_home wasn't updated first :(
      cmd << " -m" unless opts[:create_home] == false
      cmd << " -G #{opts[:groups].join(' ')}" if opts[:groups]
      cmd << " -s #{opts[:shell] || "/bin/bash"}"
      cmd << " -u #{opts[:uid]}" if opts[:uid]
      cmd << " -g #{opts[:gid]}" if opts[:gid]
      cmd << " #{username} < /dev/null"
      cmd << " > /dev/null 2>&1 | grep -v blocks" if opts[:quiet]
      interpreter.sh(cmd)
    end
  end

  # TODO AccountManager#update_user -- implement
  ### def update_user(username, opts={}) dispatch(username, opts) end

  # See AccountManager#remove_user
  def remove_user(username, opts={})
    return _remove_user_helper(username, opts) do |username, opts|
      # Options: -r -- remove the home directory and mail spool
      cmd = "userdel"
      cmd << " -r" unless opts[:remove_home] == false
      cmd << " #{username}"
      cmd << " > /dev/null" if opts[:quiet]
      interpreter.sh(cmd)
    end
  end

  # See AccountManager#add_groups_to_user
  def add_groups_to_user(groups, username)
    return _add_groups_to_user_helper(groups, username) do |missing, username|
      matches = [groups_for_user(username).to_a, groups.to_a].flatten.uniq
      cmd = "usermod -G #{matches.join(',')} #{username}"
      interpreter.sh(cmd)
    end
  end

  # See AccountManager#remove_groups_from_user
  def remove_groups_from_user(groups, username)
    return _remove_groups_from_user_helper(groups, username) do |present, username|
      matches = groups_for_user(username).to_a - groups.to_a
      cmd = "usermod -G #{matches.join(',')} #{username}"
      interpreter.sh(cmd)
    end
  end

  #.......................................................................

  # See AccountManager#add_group
  def add_group(groupname, opts={})
    return false if has_group?(groupname)
    cmd = "groupadd"
    cmd << " -g #{opts[:gid]}" if opts[:gid]
    cmd << " #{groupname}"
    interpreter.sh(cmd)

    manager.invalidate(:groups)

    add_users_to_group(opts[:members], groupname) if opts[:members]
    return groups[groupname]
  end

  # TODO AccountManager#update_group -- implement
  ### def update_group(groupname, opts={}) dispatch(groupname, opts) end

  # See AccountManager#remove_group
  def remove_group(groupname, opts={})
    return false unless has_group?(groupname)
    cmd = "groupdel #{groupname}"
    interpreter.sh(cmd)

    manager.invalidate(:groups)

    return true
  end

  # See AccountManager#add_users_to_group
  def add_users_to_group(users, groupname)
    _add_users_to_group_helper(users, groupname) do |missing, groupname|
      u2g = users_to_groups
      for username in missing
        groups = Set.new(groupname)
        groups.merge(u2g[username]) if u2g[username]
        groups = groups.to_a
        cmd = "usermod -G #{groups.join(',')} #{username}"
        interpreter.sh(cmd)
      end
    end
  end

  # See AccountManager#remove_users_from_group
  def remove_users_from_group(users, groupname)
    _remove_users_from_group_helper(users, groupname) do |present, groupname|
      u2g = users_to_groups
      for username in present
        user_groups = u2g[username]
        cmd = "usermod -G #{(user_groups.to_a-[groupname]).join(',')} #{username}"
        interpreter.sh(cmd)
      end
    end
  end
end

