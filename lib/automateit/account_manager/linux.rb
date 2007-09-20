# == AccountManager::Linux
#
# A Linux-specific driver for the AccountManager.
class ::AutomateIt::AccountManager::Linux < ::AutomateIt::AccountManager::Portable
  depends_on \
    :programs => %w(useradd usermod userdel groupadd groupmod groupdel), 
    :callbacks => [lambda{AutomateIt::AccountManager::Portable.has_etc?}]

  def suitability(method, *args) # :nodoc:
    return available? ? 2 : 0
  end

  def setup(*args) # :nodoc:
    super(*args)
  end

  # Is "nscd" available on this platform?
  def nscd?
    @nscd ||= interpreter.which("nscd")
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
    interpreter.sh(cmd)
    interpreter.sh("nscd --invalidate passwd") if nscd?

    unless opts[:group] == false
      groupname = opts[:group] || username
      unless has_group?(groupname)
        opts = {:members => [username]}
        # In preview mode, user doesn't exist and has no UID
        opts[:gid] = users[username].uid if writing?
        add_group(groupname, opts)
      end
    end

    passwd(username, opts[:passwd]) if opts[:passwd]

    return users[username]
  end

  # TODO AccountManager#update_user -- implement
  ### def update_user(username, opts={}) dispatch(username, opts) end

  # See AccountManager#remove_user
  def remove_user(username, opts={})
    return false unless has_user?(username)
    # Options: -r -- remove the home directory and mail spool
    cmd = "userdel"
    cmd << " -r" unless opts[:remove_home] == false
    cmd << " #{username}"
    cmd << " > /dev/null" if opts[:quiet]
    interpreter.sh(cmd)
    interpreter.sh("nscd --invalidate passwd") if nscd?
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
    interpreter.sh("nscd --invalidate group") if nscd?
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
    interpreter.sh("nscd --invalidate group") if nscd?
    return removeable
  end

  # See AccountManager#passwd
  def passwd(user, password, opts={})
    quiet = (opts[:quiet] or not log.info?)

    unless users[user]
      if preview?
        log.info(PNOTE+"Setting password for user: #{user}")
        return true
      else
        raise ArgumentError.new("No such user: #{user}")
      end
    end

    require 'open4'
    require 'expect'
    require 'pty'

    case user
    when Symbol: user = user.to_s
    when Integer: user = users[user]
    when String: # leave it alone
    else raise TypeError.new("Unknown user type: #{user.class}")
    end

    exitstruct = Open4::popen4("passwd %s 2>&1" % user) do |pid, sin, sout, serr|
      $expect_verbose = ! quiet
      2.times do
        sout.expect(/:/)
        sin.puts password
        puts "*" * 12 unless quiet
      end
    end

    return exitstruct.exitstatus.zero?
  end

  #.......................................................................

  # See AccountManager#add_group
  def add_group(groupname, opts={})
    return false if has_group?(groupname)
    cmd = "groupadd"
    cmd << " -g #{opts[:gid]}" if opts[:gid]
    cmd << " #{groupname}"
    interpreter.sh(cmd)
    interpreter.sh("nscd --invalidate group") if nscd?
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
    interpreter.sh("nscd --invalidate group") if nscd?
    return true
  end

  # See AccountManager#add_users_to_group
  def add_users_to_group(users, groupname)
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

    for username in missing
      cmd = "usermod -a -G #{groupname} #{username}"
      interpreter.sh(cmd)
    end
    interpreter.sh("nscd --invalidate group") if nscd?
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
    interpreter.sh("nscd --invalidate group") if nscd?
    return present
  end
end
