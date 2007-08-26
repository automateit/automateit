require 'automateit'

module AutomateIt
  # == ShellManager
  #
  # The ShellManager provides UNIX-like shell commands for the Interpreter.
  class ShellManager < Plugin::Manager
    require 'automateit/shell_manager/portable.rb'
    require 'automateit/shell_manager/unix.rb'

    # FIXME noop calls to FileUtils must return true to indicate that an action would have been taken, rather than returning nil to indicate that nothing was actually done
    # TODO write docs for all these commands
    alias_methods :sh, :which, :which!, :mktemp, :mktempdir, :mktempdircd, :chperm, :umask
    alias_methods :cd, :pwd, :mkdir, :mkdir_p, :rmdir, :ln, :ln_s, :ln_sf, :cp, :cp_r, :mv, :rm, :rm_r, :rm_rf, :install, :chmod, :chmod_R, :chown, :chown_R, :touch

    #...[ Custom commands ].................................................

    def sh(*commands) dispatch(*commands) end

    def which(command) dispatch(command) end

    def which!(command) dispatch(command) end

    def mktemp(path=nil, &block) dispatch(path, &block) end

    def mktempdir(path=nil, &block) dispatch(path, &block) end

    def mktempdircd(path=nil, &block) dispatch(path, &block) end

    def chperm(targets, opts={}) dispatch(targets, opts) end

    def umask(mode=nil, &block) dispatch(mode, &block) end

    #...[ FileUtils wrappers ]...............................................

    def cd(dir, opts={}, &block) dispatch(dir, opts, &block) end
    def pwd() dispatch() end
    def mkdir(dirs, opts={}, &block) dispatch(dirs, &block) end
    def mkdir_p(dirs, opts={}, &block) dispatch(dirs, &block) end

    def rmdir(dirs) dispatch(dirs) end

    def ln(source, target, opts={}) dispatch(source, target, opts) end
    def ln_s(sources, target, opts={}) dispatch(sources, target, opts) end
    def ln_sf(sources, target, opts={}) dispatch(sources, target, opts) end

    def cp(sources, target, opts={}) dispatch(sources, target, opts) end
    def cp_r(sources, target, opts={}) dispatch(sources, target, opts) end

    def mv(sources, target) dispatch(sources, target) end

    def rm(targets, opts={}) dispatch(targets, opts) end
    def rm_r(targets, opts={}) dispatch(targets, opts) end
    def rm_rf(targets, opts={}) dispatch(targets, opts) end

    def install(source, target, mode) dispatch(source, target, mode) end

    def chmod(mode, targets, opts={}) dispatch(mode, targets, opts) end
    def chmod_R(mode, targets, opts={}) dispatch(mode, targets, opts) end

    def chown(user, group, targets, opts={}) dispatch(user, group, targets, opts) end
    def chown_R(user, group, targets, opts={}) dispatch(user, group, targets, opts) end

    def touch(targets) dispatch(targets) end
  end # class ShellManager
end # module AutomateIt
