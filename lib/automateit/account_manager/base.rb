# == AccountManager::BaseDriver
#
# Base class for all AccountManager drivers.
class ::AutomateIt::AccountManager::BaseDriver < ::AutomateIt::Plugin::Driver
  protected

  def _passwd_helper(user, password, opts={}, &block)
    users = manager.users

    unless users[user]
      if preview?
        log.info(PNOTE+"Setting password for user: #{user}")
        return true
      else
        raise ArgumentError.new("No such user: #{user}")
      end
    end

    case user
    when Symbol: user = user.to_s
    when Integer: user = users[user]
    when String: # leave it alone
    else raise TypeError.new("Unknown user type: #{user.class}")
    end

    return block.call(user, password, opts)
  end

  def _add_user_helper(username, opts={}, &block)
    return false if has_user?(username)

    # Create group first, then the user. Necessary because some OSes can't add users with non-existent groups.

    if opts[:personal_group].nil? and not opts[:group] and not opts[:gid]
      opts[:personal_group] = true
    end

    # FIXME how to default personal_group to false?
    # FIXME what if want to add user to a specific group, rather than creating?
    # FIXME what if want or not want to crease user group?
    # FIXME how to find an unused gid/uid combo?

    unless opts[:group] == false
      groupname = opts[:group] || username
      unless has_group?(groupname)
        if not opts[:uid] and not opts[:gid] and group = add_group(groupname, opts)
          opts[:uid] = opts[:gid] = group.gid
        end
      end
    end

    block.call(username, opts)

    passwd_opts = {:quiet => opts[:quiet]}
    manager.passwd(username, opts[:passwd], passwd_opts) if opts[:passwd]

    manager.invalidate(:passwd)
    return users[username]
  end

  def _remove_user_helper(username, opts={}, &block)
    return false unless has_user?(username)

    block.call(username, opts)
    manager.invalidate(:passwd)
    remove_group(username) if has_group?(username)

    return true
  end

  def _add_groups_to_user_helper(groups, username, &block)
    groups = [groups].flatten
    present = groups_for_user(username)
    missing = groups - present
    return false if missing.empty?

    block.call(missing, username)
    manager.invalidate(:group)

    return missing
  end

  def _remove_groups_from_user_helper(groups, username, &block)
    groups = [groups].flatten
    matched = groups_for_user(username)
    present = groups & matched
    return false if present.empty?

    block.call(present, username)
    manager.invalidate(:group)

    return present
  end

  def _add_users_to_group_helper(users, groupname, &block)
    users = [users].flatten
    # XXX Include pwent.gid?
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

    block.call(missing, groupname)
    manager.invalidate(:groups)

    return missing
  end

  def _remove_users_from_group_helper(users, groupname, &block)
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

    block.call(present, groupname)
    manager.invalidate(:groups)

    return present
  end
end
