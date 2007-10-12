# == ShellManager::Portable
#
# Pure-Ruby, portable driver for ShellManager provides Unix-like shell
# commands for manipulating files and executing commands.
#
# It does not provide commands for:
# * #which
# * #which!
class AutomateIt::ShellManager::Portable < AutomateIt::ShellManager::BaseDriver
  depends_on :nothing

  def suitability(method, *args) # :nodoc:
    return available? ? 1 : 0
  end

  def broken?
    RUBY_PLATFORM =~ /mswin|java/
  end
  private :broken?

  def provides_mode?
    ! broken?
  end

  def provides_ownership?
    ! broken?
  end

  #...[ Custom commands ].................................................

  # See ShellManager#backup
  def backup(*sources)
    sources, opts = args_and_opts(*sources)

    targets = []
    for source in sources
      is_dir = File.directory?(source)

      tempster_opts = {
        :verbose => false,
        :noop => noop?,
        :delete => false,
        :dir => File.dirname(source),
        :prefix => "%s.%s" % [File.basename(source), Time.now.to_i],
        :suffix => ".bak",
        :kind => is_dir ? :directory : :file,
      }

      target = ::Tempster.tempster(tempster_opts)

      log.silence(opts[:quiet] ? Logger::WARN : log.level) do
        if is_dir
          cp_opts = {}
          cp_opts[:recursive] = true if is_dir
          cp_opts[:preserve] = :try

          source_children = _directory_contents(source)
          #puts "sc: %s" % source_children.inspect

          interpreter.cp_r(source_children, target, cp_opts)
        else
          interpreter.cp(source, target)
        end
      end

      targets << target
    end
    return sources.size == 1 ? targets.first : targets
  end

  # See ShellManager#sh
  def sh(*commands)
    args, opts = args_and_opts(*commands)
    log.info(PEXEC+"#{args.join(' ')}")
    return writing? ? system(*args) : true
  end

  def _mktemp_helper(kind, name=nil, opts={}, &block)
    # Tempster takes care of rethrowing exceptions
    opts[:name] = name || "automateit_temp"
    opts[:message_callback] = lambda{|msg| log.info(PEXEC+msg)}
    opts[:noop] = interpreter.preview?
    ::Tempster.send(kind, opts, &block)
  end
  private :_mktemp_helper

  # See ShellManager#mktemp
  def mktemp(name=nil, &block)
    _mktemp_helper(:mktemp, name, &block)
  end

  # See ShellManager#mktempdir
  def mktempdir(name=nil, &block)
    _mktemp_helper(:mktempdir, name, &block)
  end

  # See ShellManager#mktempdircd
  def mktempdircd(name=nil, &block)
    _mktemp_helper(:mktempdircd, name, &block)
  end

  # See ShellManager#umask
  def umask(mode=nil, &block)
    if mode
      old = File::umask
      File::umask(mode)
      if block
        begin
          block.call
        rescue Exception => e
          raise e
        ensure
          File::umask(old)
        end
      end
    else
      File::umask
    end
  end

  #...[ FileUtils wrappers ]...............................................

  # See ShellManager#cd
  def cd(dir, opts={}, &block)
    if block
      log.enqueue(:info, PEXEC+(block ? "pushd" : "cd")+" "+dir)
      begin
        if writing? or File.directory?(dir)
          FileUtils.cd(dir, &block)
        else
          block.call(true)
        end
      rescue Exception => e
        raise e
      ensure
        log.dequeue(:info, PEXEC+"popd # => #{pwd}")
      end
    else
      FileUtils.cd(dir) if writing?
    end
    return dir
  end

  # See ShellManager#pwd
  def pwd()
    return FileUtils.pwd()
  end

  # See ShellManager#mkdir
  def mkdir(dirs, opts={}, &block)
    _replace_owner_with_user(opts)
    kind = opts[:parents] ? :mkdir_p : :mkdir
    missing = [dirs].flatten.select{|dir| ! File.directory?(dir)}
    result = false
    if missing.empty? and not block
      chperm(opts) if opts[:user] or opts[:group] or opts[:mode]
      return result
    end
    unless missing.empty?
      cmd = kind.to_s.gsub(/_/, ' -')
      log.info(PEXEC+"#{cmd} #{missing.join(" ")}")
      result = [FileUtils.send(kind, missing, _fileutils_opts)].flatten
      result = result.first if [dirs].flatten.size == 1
    end
    if block
      if missing.size > 1
        raise ArgumentError.new(
          "can only use a block if you mkdir a single directory")
      end
      dir = [dirs].flatten.first
      cd(dir) do
        block.call(result)
      end
    end
    chperm(opts) if opts[:user] or opts[:group] or opts[:mode]
    return missing
  end

  # See ShellManager#mkdir_p
  def mkdir_p(dirs, opts={}, &block)
    mkdir(dirs, {:parents => true}.merge(opts), &block)
  end

  # See ShellManager#rmdir
  def rmdir(dirs)
    present = [dirs].flatten.select{|dir| File.directory?(dir)}
    return false if present.empty?
    log.info(PEXEC+"rmdir #{String === dirs ? dirs : dirs.join(' ')}")
    FileUtils.rmdir(present, _fileutils_opts)
    return present
  end

  # See ShellManager#install
  def install(source, target, mode=nil)
    cp_rv = nil
    chmod_rv = nil
    log.silence(Logger::WARN) do
      cp_rv = cp(source, target)
      chmod_rv = chmod(mode, peer_for(source, target)) if mode
    end

    return false unless cp_rv or chmod_rv

    log.info(PEXEC+"install%s %s %s" %
             [mode ? ' -m 0%o' % mode : '', source, target])
    return source
  end

  # See ShellManager#cp
  def cp(sources, target, opts={})
    # TODO ShellManager::Portable#cp -- rather funky, needs a code review
    fu_opts = _fileutils_opts
    for opt in [:noop, :verbose]
      opt = opt.to_sym
      fu_opts[opt] = opts[opt] if opts[opt]
    end

    fu_opts_with_preserve = fu_opts.clone
    fu_opts_with_preserve[:preserve] = \
      if opts[:preserve] == :try
        fsim = File::Stat.instance_methods
        (fsim.include?("uid") and fsim.include?("gid") and
         fsim.include?("mode") and fsim.include?("atime"))
      else
        opts[:preserve]
      end

    changed = []
    sources_a = [sources].flatten
    sources_a.each do |parent|
      Find.find(parent) do |child|
        source_fn = File.directory?(child) ? child+"/" : child
        target_dir = File.directory?(target)
        target_fn = peer_for(source_fn, target)

        log.debug(PNOTE+"comparing %s => %s" % [source_fn, target_fn])
        source_st = File.stat(source_fn)
        is_copy = false
        begin
          begin
            target_st = File.stat(target_fn)

            unless target_dir
              # Is the file obviously different?
              if source_st.file?
                for kind in %w(size mtime)
                  next if kind == "mtime" and ! opts[:preserve]
                  unless source_st.send(kind) == target_st.send(kind)
                    log.debug(PNOTE+"%s not same %s" % [target_fn, kind])
                    raise EOFError.new
                  end
                end

                unless FileUtils.identical?(source_fn, target_fn)
                  log.debug(PNOTE+"%s not identical" % target_fn)
                  raise EOFError.new
                end
              end

              # File just needs to be altered
              if opts[:preserve]
                unless source_st.mode == target_st.mode
                  changed << child
                  log.debug(PNOTE+"%s not same mode" % target_fn)
                  chmod(source_st.mode, target_fn, fu_opts)
                end
                unless source_st.uid == target_st.uid and source_st.gid == target_st.gid
                  changed << child
                  log.debug(PNOTE+"%s not same uid/gid" % target_fn)
                  chown(source_st.uid, source_st.gid, target_fn, fu_opts)
                end
              end
            end
          rescue EOFError
            changed << child
            is_copy = true
          end
        rescue Errno::ENOENT
          changed << child
          log.debug(PNOTE+"%s not present" % target_fn)
          is_copy = true
        end
        if is_copy
          log.info(PEXEC+"cp%s %s %s" % [opts[:recursive] ? ' -r' : '', source_fn, target_fn])
          ## puts "fo %s" % fu_opts.inspect
          ## puts "fowp %s" % fu_opts_with_preserve.inspect
          FileUtils.cp_r(source_fn, target_fn, fu_opts_with_preserve)
        end
      end
    end

    result = \
      if changed.empty?
        false
      else
        if sources_a.size == 1
          changed.first
        else
          changed.uniq
        end
      end
    return result
  end

  # See ShellManager#cp_r
  def cp_r(sources, target, opts={})
    cp(sources, target, {:recursive => true}.merge(opts))
  end

  # See ShellManager#cp_R
  def cp_R(*args)
    cp_r(*args)
  end

  # See ShellManager#mv
  def mv(sources, target)
    present = [sources].flatten.select{|entry| File.exists?(entry)}
    return false if present.empty?
    present = present.first if present.size == 1
    FileUtils.mv(present, target, _fileutils_opts) && present
    return present
  end

  # See ShellManager#rm
  def rm(targets, opts={})
    kind = \
      if opts[:recursive] and opts[:force]
        :rm_rf
      elsif opts[:recursive]
        :rm_r
      else
        :rm
      end

    present = [targets].flatten.select{|entry| File.exists?(entry)}
    return false if present.empty?

    msg = "rm"
    if opts[:recursive] and opts[:force]
      msg << " -rf"
    elsif opts[:recursive]
      msg << " -r"
    elsif opts[:force]
      msg << " -f"
    end
    msg << " " << present.join(' ')
    log.info(PEXEC+msg)

    present = present.first if present.size == 0

    FileUtils.send(kind, present, _fileutils_opts)
    return present
  end

  # See ShellManager#rm_r
  def rm_r(targets, opts={})
    rm(targets, {:recursive => true}.merge(opts))
  end

  # See ShellManager#rm_rf
  def rm_rf(targets, opts={})
    rm(targets, {:recursive => true, :force => true}.merge(opts))
  end

  FILE_MASK = 0100000
  DIRECTORY_MASK = 040000

  # See ShellManager#chperm
  def chperm(targets, opts={})
    _replace_owner_with_user(opts)
    user = \
      if opts[:user]
        opts[:user] = opts[:user].to_s if opts[:user].is_a?(Symbol)
        if opts[:user].is_a?(String)
          begin
            Etc.getpwnam(opts[:user]).uid
          rescue ArgumentError
            :not_present
          end
        else
          opts[:user]
        end
      end

    group = \
      if opts[:group]
        opts[:group] = opts[:group].to_s if opts[:group].is_a?(Symbol)
        if opts[:group].is_a?(String)
          begin
            Etc.getgrnam(opts[:group]).gid
          rescue ArgumentError
            :not_present
          end
        else
          opts[:group]
        end
      end

    modified_entries = []
    modified_ownership = false
    modified_permission = false
    Find.find(*targets) do |path|
      modified = false
      stat = writing? || File.exists?(path) ? File.stat(path) : nil
      if opts[:mode]
        # TODO ShellManager::Portable#chperm -- process chmod symbolic strings, e.g., [ugoa...][[+-=][rwxXstugo...]...][,...]
        mode = opts[:mode] | (stat.directory? ? DIRECTORY_MASK : FILE_MASK) if stat
        unless stat and (mode ^ stat.mode).zero?
          modified = true
          modified_permission = true
          File.chmod(mode, path) if writing?
        end
      end
      if user and (not stat or user != stat.uid)
        modified = true
        modified_ownership = true
        File.chown(user, nil, path) if writing?
      end
      if group and (not stat or group != stat.gid)
        modified = true
        modified_ownership = true
        File.chown(nil, group, path) if writing?
      end
      modified_entries << path if modified
      Find.prune if not opts[:recursive] and File.directory?(path)
    end

    return false if modified_entries.empty?

    display_entries = opts[:details] ? modified_entries : targets
    display_entries = [display_entries].flatten

    if modified_permission
      msg = "chmod"
      msg << " -R" if opts[:recursive]
      msg << " 0%o" % opts[:mode] if opts[:mode]
      msg << " " << display_entries.join(' ')
      log.info(PEXEC+msg)
    end
    if modified_ownership
      msg = "chown"
      msg << " -R" if opts[:recursive]
      msg << " %s" % opts[:user] if opts[:user]
      msg << ":" if opts[:user] and opts[:group]
      msg << "%s" % opts[:group] if opts[:group]
      msg << " " << display_entries.join(' ')
      log.info(PEXEC+msg)
    end
    return targets.is_a?(String) ? modified_entries.first : modified_entries
  end

  # See ShellManager#chmod
  def chmod(mode, targets, opts={})
    chperm(targets, {:mode => mode}.merge(opts))
  end

  # See ShellManager#chmod_R
  def chmod_R(mode, targets, opts={})
    chmod(mode, targets, {:recursive => true}.merge(opts))
  end

  # See ShellManager#chown
  def chown(user, group, targets, opts={})
    chperm(targets, {:user => user, :group => group}.merge(opts))
  end

  # See ShellManager#chown_R
  def chown_R(user, group, targets, opts={})
    chown(user, group, targets, {:recursive => true}.merge(opts))
  end

  # See ShellManager#touch
  def touch(targets, opts={})
    like = opts.delete(:like)
    stamp = opts.delete(:stamp)
    quiet = opts.delete(:quiet) == true ? true : false
    time = \
      if stamp
        stamp
      elsif like
        begin
          File.stat(like).mtime
        rescue Errno::ENOENT => e
          if preview?
            Time.now
          else
            raise e
          end
        end
      else
        Time.now
      end

    unless quiet
      msg = "touch"
      msg << " --reference %s" % like if like
      msg << " --stamp %s" % stamp if stamp
      msg << " " << [targets].flatten.join(" ")
      log.info(PEXEC+msg)
    end

    results = []
    for target in [targets].flatten
      begin
        stat = File.stat(target)
        next if stat.mtime.to_i == time.to_i
      rescue Errno::ENOENT
        File.open(target, "a"){} unless preview?
      end
      File.utime(time, time, target) unless preview?
      results << target
    end

    return false if results.empty?
    return targets.is_a?(String) ? results.first : results
  end
end
