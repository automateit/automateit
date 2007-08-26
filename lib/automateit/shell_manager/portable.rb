module AutomateIt
  class ShellManager
    # == ShellManager::Portable
    #
    # A pure-Ruby, portable driver for ShellManager provides common shell
    # commands.
    #
    # It does not provide commands for:
    # * #which
    # * #which!
    class Portable < Plugin::Driver
      depends_on :nothing

      def suitability(method, *args) # :nodoc:
        return 1
      end

      #...[ Custom commands ].................................................

      # Returns hash of verbosity and noop settings for FileUtils commands.
      def _fileutils_opts
        opts = {}
        opts[:verbose] = false # Generate our own log messages
        opts[:noop] = true if noop?
        return opts
      end
      private :_fileutils_opts

      def sh(*commands)
        args, opts = args_and_opts(*commands)
        log.info(PEXEC+"#{args.join(' ')}")
        return writing? ? system(*args) : true
      end

      def rbsync(sources, target)
        # FIXME replace with new version
        # TODO generalize with cp, cp_r, install
        if File.exists?(target)
          cmd = "diff -qr"
          for t in [sources, target].flatten
            cmd << %{ "#{t}"}
          end
          cmd << " < /dev/null > /dev/null"
          log.debug(PEXEC+cmd)
          return false if system(cmd)
        end
        cp(sources, target, _fileutils_opts)
      end

      def _mktemp_helper(kind, name=nil, opts={}, &block)
        # Tempster takes care of rethrowing exceptions
        opts = {:name => name}.merge(opts)
        ::Tempster.send(kind, opts, &block)
      end

      def mktemp(name=nil, &block)
        _mktemp_helper(:mktemp, name, &block)
      end

      def mktempdir(name=nil, &block)
        _mktemp_helper(:mktempdir, name, &block)
      end

      def mktempdircd(name=nil, &block)
        _mktemp_helper(:mktempdircd, name, &block)
      end

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

      def cd(dir, opts={}, &block)
        if block
          log.enqueue(:info, PEXEC+"cd #{dir}")
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
            log.dequeue(:info, PEXEC+"cd -")
          end
        else
          FileUtils.cd(dir) if writing?
        end
      end

      def pwd()
        FileUtils.pwd()
      end

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
        return result
      end

      def mkdir_p(dirs, opts={}, &block)
        mkdir(dirs, {:parents => true}.merge(opts), &block)
      end

      def rmdir(dirs)
        present = [dirs].flatten.select{|dir| File.directory?(dir)}
        return false if present.empty?
        log.info(PEXEC+"rmdir #{String === dirs ? dirs : dirs.join(' ')}")
        FileUtils.rmdir(present, _fileutils_opts)
      end

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
      end

      def ln_s(sources, target, opts={})
        ln(sources, target, {:symbolic => true}.merge(opts))
      end

      def ln_sf(sources, target, opts={})
        ln(sources, target, {:symbolic => true, :force => true}.merge(opts))
      end

      def install(source, target, mode)
        raise NotImplementedError
        # TODO needs more sophisticated algorithm, maybe combine with copy
        # TODO log
        source_stat = File.stat(source)
        target_file = (File.directory?(target) || File.stat(target).symlink?) ?
          File.join(target, File.basename(source)) : target
        target_stat = File.exists?(target_file) ? File.stat(target) : nil
        unless target_stat and FileUtils.identical?(source, target_file)
          FileUtils.install(source, target, mode,
                            {:preserve => true}.merge(_fileutils_opts))
        end
      end

      def cp(sources, target, opts={})
        raise NotImplementedError
        # TODO needs much more sophisticated algorithm
        # TODO log
        FileUtils.cp(sources, target, _fileutils_opts)
      end

      def cp_r(sources, target, opts={})
        cp(sources, target, {:recursive => true}.merge(opts))
      end

      def mv(sources, target)
        present = [sources].flatten.select{|entry| File.exists?(entry)}
        return false if present.empty?
        present = present.first if present.size == 1
        FileUtils.mv(present, target, _fileutils_opts) && present
      end

      def rm(targets, opts={})
        kind = if opts[:recursive] and opts[:force]
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
        FileUtils.send(kind, present, _fileutils_opts) && present
      end

      def rm_r(targets, opts={})
        rm(targets, {:recursive => true}.merge(opt))
      end

      def rm_rf(targets, opts={})
        rm(targets, {:recursive => true, :force => true}.merge(opts))
      end

      FILE_MASK = 0100000
      DIRECTORY_MASK = 040000

      def chperm(targets, opts={})
        # TODO move logging inside chperm and have it generate a log based on params, e.g. if only mode is specified, "chmod", if only user/mode then "chown", if both either show both or "chperm"
        # TODO provide options for :report => :detailed, :report => :terse, :quiet => true. The :detailed mode logs and returns list of all disk entries modified; this is the default and shows complete information. The :terse logs and reports only user-supplied targets that were modified, creating cuumulative logs like "chmod -R your_target" if anything within your_target changed rather than listing the specific files; this is useful when operating on large trees where you don't want to be drowned by output. The :quiet option turns off logging entirely. The big idea is to allow the user to choose how much to output, especially in cases where it outputs too much.
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
            # TODO process mode strings [ugoa...][[+-=][rwxXstugo...]...][,...]
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

        if modified_entries.empty?
          return false
        elsif targets.is_a?(String)
          return modified_entries.first
        else
          return modified_entries
        end
      end

      def chmod(mode, targets, opts={})
        results = chperm(targets, {:mode => mode}.merge(opts))
        # TODO move logging inside chperm
        log.info(PEXEC+"chmod#{opts[:recursive] ? ' -R' : ''} #{mode} #{results.is_a?(String) ? results : results.join(' ')}") if results and not results.empty?
        return results
      end

      def chmod_R(mode, targets, opts={})
        chmod(mode, targets, {:recursive => true}.merge(opts))
      end

      def chown(user, group, targets, opts={})
        results = chperm(targets, {:user => user, :group => group}.merge(opts))
        # TODO move logging inside chperm
        log.info(PEXEC+"chown#{opts[:recursive] ? ' -R' : ''} #{user} #{group} #{results.is_a?(String) ? results : results.join(' ')}") if results and not results.empty?
        return results
      end

      def chown_R(user, group, targets, opts={})
        chown(user, group, targets, {:recursive => true}.merge(opts))
      end

      def touch(targets)
        log.info(PEXEC+"touch #{String === targets ? targets : targets.join(' ')}")
        FileUtils.touch(targets, _fileutils_opts)
      end
    end # Portable
  end
end
