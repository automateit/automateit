# == AccountManager::POSIX
#
# A POSIX driver for the AccountManager.
class ::AutomateIt::AccountManager::POSIX < ::AutomateIt::AccountManager::BaseDriver
  depends_on :programs => %w(useradd usermod userdel groupadd groupmod groupdel)

  def suitability(method, *args) # :nodoc:
    # Level must be higher than Portable
    return available? ? 2 : 0
  end

  #.......................................................................

  # See AccountManager#add_user
  def add_user(username, opts={})
    return _add_user_helper(username, opts) do |username, opts|
      cmd = "useradd"
      cmd << " -c #{opts[:description] || username}"
      cmd << " -d #{opts[:home]}" if opts[:home]
      cmd << " -m" unless opts[:create_home] == false
      cmd << " -G #{opts[:groups].join(',')}" if opts[:groups]
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
      targets = (groups_for_user(username) + missing).uniq

      cmd = "usermod -G #{targets.join(',')} #{username}"
      interpreter.sh(cmd)
    end
  end

  # See AccountManager#remove_groups_from_user
  def remove_groups_from_user(groups, username)
    return _remove_groups_from_user_helper(groups, username) do |present, username|
      matches = (groups_for_user(username) - [groups].flatten).uniq
      cmd = "usermod -G #{matches.join(',')} #{username}"
      interpreter.sh(cmd)
    end
  end

  #.......................................................................

  # See AccountManager#add_group
  def add_group(groupname, opts={})
    modified = false
    unless has_group?(groupname)
      modified = true

      cmd = "groupadd"
      cmd << " -g #{opts[:gid]}" if opts[:gid]
      cmd << " #{groupname}"
      interpreter.sh(cmd)

      manager.invalidate(:groups)
    end

    if opts[:members]
      modified = true
      add_users_to_group(opts[:members], groupname)
    end

    return modified ? groups[groupname] : false
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
      for username in missing
        targets = (groups_for_user(username) + [groupname]).uniq
        cmd = "usermod -G #{targets.join(',')} #{username}"
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
        # FIXME tries to include non-present groups, should use some variant of present
        cmd = "usermod -G #{(user_groups.to_a-[groupname]).join(',')} #{username}"
        interpreter.sh(cmd)
      end
    end
  end

  # Dispatch common names to Etc, but don't define these methods here because
  # that would make available? and suitability think these exist, when in fact,
  # they're just wrappers.
  def method_missing(symbol, *args, &block)
    case symbol
    when :users, :has_user?, :groups, :has_group?, :groups_for_user, :users_for_group, :users_to_groups
      manager.send(symbol, *args, &block)
    else
      super(symbol, *args, &block)
    end
  end
end
