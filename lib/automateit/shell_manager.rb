require 'automateit'

module AutomateIt
  # Provides UNIX-like shell commands for the Interpreter. See documentation in
  # ShellManager::POSIX
  class ShellManager < Plugin::Manager
    # FIXME noop calls to FileUtils must return true to indicate that an action would have been taken, rather than returning nil to indicate that nothing was actually done
    # FIXME write specs for all these commands
    # TODO write docs for all these commands
    alias_methods :sh, :which, :raise_unless_which, :mktemp, :mktempdir, :mktempdircd
    alias_methods :cd, :pwd, :mkdir, :mkdir_p, :rmdir, :ln, :ln_s, :ln_sf, :cp, :cp_r, :mv, :rm, :rm_r, :rm_rf, :install, :chmod, :chmod_R, :touch

    #...[ Custom commands ].................................................

    def sh(*commands) dispatch(*commands) end

    def which(command) dispatch(command) end

    def raise_unless_which(command) dispatch(command) end

    def mktemp(path=nil, &block) dispatch(path, &block) end

    def mktempdir(path=nil, &block) dispatch(path, &block) end

    def mktempdircd(path=nil, &block) dispatch(path, &block) end

    #...[ FileUtils wrappers ]...............................................

    def cd(dir, opts={}, &block) dispatch(dir, opts, &block) end
    def pwd() dispatch() end
    def mkdir(dirs) dispatch(dirs) end
    def mkdir_p(dirs) dispatch(dirs) end

    def rmdir(dirs) dispatch(dirs) end

    def ln(source, target) dispatch(source, target) end
    def ln_s(sources, target) dispatch(sources, target) end
    def ln_sf(sources, target) dispatch(sources, target) end

    def cp(sources, target) dispatch(sources, target) end
    def cp_r(sources, target) dispatch(sources, target) end

    def mv(sources, target) dispatch(sources, target) end

    def rm(targets) dispatch(targets) end
    def rm_r(targets) dispatch(targets) end
    def rm_rf(targets) dispatch(targets) end

    def install(source, target, mode) dispatch(source, target, mode) end

    def chmod(mode, targets) dispatch(mode, targets) end
    def chmod_R(mode, targets) dispatch(mode, targets) end

    def chown(user, group, targets) dispatch(user, group, targets) end
    def chown_R(user, group, targets) dispatch(user, group, targets) end

    def touch(targets) dispatch(targets) end

    #-----------------------------------------------------------------------

    class POSIX < Plugin::Driver
      # XXX Interrogate individual methods for fine-grained control? E.g. Windows can run almost all of these pure ruby commands, so it should run them rather than failing just because a few aren't there.
      depends_on :programs => %w(which)

      def suitability(method, *args)
        return available? ? 1 : 0
      end

      def setup(opts={})
        super(opts)

        # XXX Intercept fu_output_message and use Interpreter#log.info instead?
        ::FileUtils.instance_variable_set(:@fileutils_output, $stdout)
        ::FileUtils.instance_variable_set(:@fileutils_label, "$$$ ")
      end

      #...[ Custom commands ].................................................

      # Returns hash of verbosity and noop settings for FileUtils commands.
      def _fileutils_opts
        opts = {}
        opts[:verbose] = true if log.level <= ::Logger::INFO
        opts[:noop] = true if noop?
        return opts
      end
      private :_fileutils_opts

      def sh(*commands)
        args, opts = args_and_opts(*commands)
        log.info("$$$ #{args.join(' ')}")
        return writing? ? system(*args) : true
      end

      def which(command)
        data = `which "#{command}" 2>&1`.chomp
        return File.exists?(data) ? data : nil
      end

      def raise_unless_which(command)
        if which(command).nil?
          raise NotImplementedError.new("command not found: #{command}")
        end
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
          log.debug("$$$ #{cmd}")
          return false if system(cmd)
        end
        cp(sources, target, _fileutils_opts)
      end

      def _mktemp_helper(kind, name=nil, opts={}, &block)
        # XXX Need pure-Ruby implementation of mktemp for directory. Unfortunately, the MkTemp gem is defective.
        raise_unless_which("mktemp")
        name ||= "automateit_mktemp.XXXXXXXXXX"
        cmd = "mktemp -t #{name} #{kind == :directory ? "-d" : ""} 2>&1"
        path = `#{cmd}`.chomp
        log.info("$$$ #{cmd} # => #{path}")
        raise ArgumentError.new("failed to create tempdir with: #{cmd}") unless File.exists?(path)
        if block
          if opts[:cd]
            cd path do
              block.call(path)
            end
          else
            block.call(path)
          end
          rm_rf(path)
        else
          return path
        end
      end

      def mktemp(name=nil, &block)
        _mktemp_helper(:file, name, &block)
      end

      def mktempdir(name=nil, &block)
        _mktemp_helper(:directory, name, &block)
      end

      def mktempdircd(name=nil, &block)
        _mktemp_helper(:directory, name, :cd => true, &block)
      end

      #...[ FileUtils wrappers ]...............................................

      def cd(dir, opts={}, &block)
        FileUtils.cd(dir, _fileutils_opts.merge(opts), &block)
      end

      def pwd()
        FileUtils.pwd()
      end

      def _mkdir(dirs, kind)
        missing = [dirs].flatten.select{|dir| ! File.directory?(dir)}
        return false if missing.empty?
        [FileUtils.send(kind, missing, _fileutils_opts)].flatten
      end
      private :_mkdir

      def mkdir(dirs)
        _mkdir(dirs, :mkdir)
      end

      def mkdir_p(dirs)
        _mkdir(dirs, :mkdir_p)
      end

      def rmdir(dirs)
        present = [dirs].flatten.select{|dir| File.directory?(dir)}
        return false if present.empty?
        FileUtils.rmdir(present, _fileutils_opts)
      end

      def _ln(kind, sources, target)
        missing = []
        for source in [sources].flatten
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
        log.debug("### _ln(%s, %s, %s) # => %s" % [kind, sources.inspect, target.inspect, missing.inspect])
        missing = missing.first if missing.size == 1
        case kind
        when :ln
          FileUtils.ln(missing, target, _fileutils_opts) && missing
        else
          FileUtils.send(kind, missing, target, _fileutils_opts) && missing
        end
      end
      private :_ln

      def ln(source, target)
        raise TypeError.new("source for hard link must be a String") unless String === source
        _ln(:ln, source, target)
      end

      def ln_s(sources, target)
        _ln(:ln_s, sources, target)
      end

      def ln_sf(sources, target)
        _ln(:ln_sf, sources, target)
      end

      def cp(sources, target)
        # TODO needs much more sophisticated algorithm
        FileUtils.cp(sources, target, _fileutils_opts)
      end
      def cp_r(sources, target)
        # TODO needs much more sophisticated algorithm
        FileUtils.cp_r(sources, target, _fileutils_opts)
      end

      def mv(sources, target)
        raise NotImplementedError # FIXME
        present = [dirs].flatten.select{|dir| File.directory?(dir)}
        return false if present.empty?
        FileUtils.mv(missing, target, _fileutils_opts)
      end

      def _rm(kind, targets)
        present = [targets].flatten.select{|entry| File.exists?(entry)}
        return false if present.empty?
        present = present.first if present.size == 0
        FileUtils.send(kind, present, _fileutils_opts) && present
      end

      def rm(targets)
        _rm(:rm_r, targets)
      end

      def rm_r(targets)
        _rm(:rm_r, targets)
      end

      def rm_rf(targets)
        _rm(:rm_rf, targets)
      end

      def install(source, target, mode)
        # TODO needs more sophisticated algorithm, maybe combine with copy
        source_stat = File.stat(source)
        target_file = (File.directory?(target) || File.stat(target).symlink?) ?
          File.join(target, File.basename(source)) : target
        target_stat = File.exists?(target_file) ? File.stat(target) : nil
        unless target_stat and FileUtils.identical?(source, target_file)
          FileUtils.install(source, target, mode,
                            {:preserve => true}.merge(_fileutils_opts))
        end
      end

      def chmod(mode, targets)
        # TODO
        # if target_stat && (target_stat.mode != source_stat.mode)
        #   chmod(source_stat.mode, target_file, _fileutils_opts)
        # end
        FileUtils.chmod(mode, targets, _fileutils_opts)
      end

      def chmod_R(mode, targets)
        # TODO
        FileUtils.chmod_R(mode, targets, _fileutils_opts)
      end

      def chown(user, group, targets)
        # TODO
        FileUtils.chown(user, group, targets, _fileutils_opts)
      end

      def chown_R(user, group, targets)
        # TODO
        FileUtils.chown_R(user, group, targets, _fileutils_opts)
      end

      def touch(targets)
        FileUtils.touch(targets, _fileutils_opts)
      end
    end
  end
end
