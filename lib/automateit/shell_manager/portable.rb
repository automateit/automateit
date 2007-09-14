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
    return %w(which which!).include?(method.to_s) ? 0 : 1
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

  def provides_symlink?
    ! broken?
  end

  def provides_hard_link?
    ! broken?
  end

  #...[ Custom commands ].................................................

  # Returns providesh of verbosity and noop settings for FileUtils commands.
  def _fileutils_opts
    opts = {}
    opts[:verbose] = false # Generate our own log messages
    opts[:noop] = true if noop?
    return opts
  end
  private :_fileutils_opts

  # See ShellManager#sh
  def sh(*commands)
    args, opts = args_and_opts(*commands)
    log.info(PEXEC+"#{args.join(' ')}")
    return writing? ? system(*args) : true
  end

  def _mktemp_helper(kind, name=nil, opts={}, &block)
    # Tempster takes care of rethrowing exceptions
    opts = {:name => name}.merge(opts)
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
          begin
            block.call(true)
          rescue Exception => e
            raise e
          end
        end
      rescue Exception => e
        raise e
      ensure
        log.dequeue(:info, PEXEC+"popd")
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
    kind = if opts[:parents]
             :mkdir_p
           else
             :mkdir
           end
    missing = [dirs].flatten.select{|dir| ! File.directory?(dir)}
    result = false
    if missing.empty? and not block
      return result
    end
    unless missing.empty?
      cmd = kind.to_s.gsub(/_/, ' -')
      log.info(PEXEC+"#{cmd} #{missing.join(" ")}")
      result = [FileUtils.send(kind, missing, _fileutils_opts)].flatten
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

  # See ShellManager#ln
  def ln(sources, target, opts={})
    kind = if opts[:symbolic] and opts[:force]
             :ln_sf
           elsif opts[:symbolic]
             :ln_s
           else
             :ln
           end
    missing = []
    sources = [sources].flatten
    if kind == :ln
      raise TypeError.new("source for hard link must be a String") unless sources.size == 1
    end
    for source in sources
      peer = File.directory?(target) ? File.join(target, File.basename(source)) : target
      begin
        peer_lstat = File.lstat(peer)
        peer_stat = File.stat(peer)
        source_stat = File.stat(source)
        case kind
        when :ln
          missing << source if peer_stat.ino != source_stat.ino
        when :ln_s, :ln_sf
          missing << source if ! peer_lstat.symlink? || peer_stat.ino != source_stat.ino
        else
          raise ArgumentError.new("unknown link kind: #{kind}")
        end
      rescue Errno::ENOENT
        missing << source
      end
    end
    return false if missing.empty?
    log.debug(PNOTE+"_ln(%s, %s, %s) # => %s" % [kind, sources.inspect, target.inspect, missing.inspect])
    missing = missing.first if missing.size == 1
    if kind == :ln
      log.info(PEXEC+"ln #{missing} #{target}")
      FileUtils.ln(missing, target, _fileutils_opts) && missing
    else
      log.info(PEXEC+"#{kind} #{String === missing ? missing : missing.join(' ')} #{target}")
      FileUtils.send(kind, missing, target, _fileutils_opts) && missing
    end
    return missing
  end

  # See ShellManager#ln_s
  def ln_s(sources, target, opts={})
    ln(sources, target, {:symbolic => true}.merge(opts))
  end

  # See ShellManager#ln_sf
  def ln_sf(sources, target, opts={})
    ln(sources, target, {:symbolic => true, :force => true}.merge(opts))
  end

  # See ShellManager#install
  def install(source, target, mode=nil)
    cp_rv = nil
    chmod_rv = nil
    log.silence(Logger::WARN) do
      cp_rv = cp(source, target)
      chmod_rv = chmod(mode, target) if mode
    end

    return false unless cp_rv or chmod_rv

    log.info(PEXEC+"install%s %s %s" %
             [mode ? ' -m 0%o' % mode : '', source, target])
    return source
  end

  # See ShellManager#cp
  def cp(sources, target, opts={})
    # TODO ShellManager::Portable#cp -- rather funky, needs a code review
    fu_opts = _fileutils_opts.merge(:noop => opts[:noop], :verbose => opts[:verbose])
    #fu_opts[:verbose] = true
    fu_opts_with_preserve = {:preserve => opts[:preserve]}.merge(fu_opts)
    changed = []
    sources_a = [sources].flatten
    sources_a.each do |parent|
      Find.find(parent) do |child|
        source_fn = File.directory?(child) ? child+"/" : child
        target_dir = File.directory?(target)
        target_fn = \
          if target_dir
            #File.join(target, source_fn.match(/#{parent}\/?(.*)$/)[1])
            File.join(target, source_fn)
          else
            target
          end
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
    present = present.first if present.size == 0
    log.info(PEXEC+"#{kind} #{String === present ? present : present.join(' ')}")
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
    user = \
      if opts[:user]
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
    Find.find(*targets) do |path|
      modified = false
      stat = writing? || File.exists?(path) ? File.stat(path) : nil
      if opts[:mode]
        # TODO ShellManager::Portable#chperm -- process chmod symbolic strings, e.g., [ugoa...][[+-=][rwxXstugo...]...][,...]
        mode = opts[:mode] | (stat.directory? ? DIRECTORY_MASK : FILE_MASK) if stat
        unless stat and (mode ^ stat.mode).zero?
          modified = true
          File.chmod(mode, path) if writing?
        end
      end
      if user and (not stat or user != stat.uid)
        modified = true
        File.chown(user, nil, path) if writing?
      end
      if group and (not stat or group != stat.gid)
        modified = true
        File.chown(nil, group, path) if writing?
      end
      modified_entries << path if modified
      Find.prune if not opts[:recursive] and File.directory?(path)
    end

    return false if modified_entries.empty?

    display_entries = \
      if opts[:report] == :details
        modified_entries
      else
        targets
      end
    display_entries = [display_entries].flatten

    if opts[:mode]
      log.info(PEXEC+"chmod%s 0%o %s" % [opts[:recursive] ? ' -R' : '',
               opts[:mode], display_entries.join(' ')])
    end
    if opts[:user] or opts[:group]
      log.info(PEXEC+"chown%s%s%s %s" % [opts[:recursive] ? ' -R' : '',
               opts[:user] ? ' %s'%opts[:user] : '',
               opts[:group] ? ' %s'%opts[:group] : '',
               display_entries.join(' ')])
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
  def touch(targets)
    log.info(PEXEC+"touch #{String === targets ? targets : targets.join(' ')}")
    FileUtils.touch(targets, _fileutils_opts)
    return targets
  end
end
