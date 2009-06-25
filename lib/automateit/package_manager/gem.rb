# == PackageManager::Gem
#
# The Gem driver for the PackageManager provides a way to manage software
# packages for RubyGems using the +gem+ command.
#
# === Specifying version of gem to use
#
# You can specify the command to use with each call using the gem option, e.g., the "gem1.8" below:
#
#   package_manager.install 'rails', :with => :gem, :gem => "gem1.8"
#
# Or set a default and all subsequent calls will use it:
#
#   package_manager[:gem].setup(:gem => "gem1.8")
#   package_manager.install 'rails', :with => :gem
class AutomateIt::PackageManager::Gem < AutomateIt::PackageManager::BaseDriver
  attr_accessor :gem

  # FIXME Can't tell which gem program is used until we can use #which, need a new paradigm for #available?
  depends_on \
    :libraries => %w(expect pty)
    ### :programs => %w(gem),

  def setup(*args)
    super(*args)

    args, opts = args_and_opts(*args)
    if opts[:gem]
      @gem = opts[:gem]
    else
      @gem ||= %w(gem gem1.8 gem1.9).inject(nil){|s,v| s ? s : interpreter.which(v)}
    end
  end

  def suitability(method, *args) # :nodoc:
    # Never select GEM as the default driver
    return 0
  end

  # See PackageManager#installed?
  def installed?(*packages)
    return _installed_helper?(*packages) do |list, opts|
      gem = opts[:gem] || self.gem
      cmd = "#{gem} list --local 2>&1"

      log.debug(PEXEC+cmd)
      data = `#{cmd}`

      # Gem lists packages out of order, which screws up the
      # install/uninstall sequence, so we need to put them back in the
      # order that the user specified.
      present = data.scan(/^([^\s\(]+)\s+\([^\)]+\)\s*$/).flatten
      available = []
      for package in list
        available << package if present.include?(package)
      end
      available
    end
  end

  # See PackageManager#not_installed?
  def not_installed?(*packages)
    _not_installed_helper?(*packages)
  end

  # Special options:
  # * :docs -- If set to false, won't install rdoc or ri.
  # * :source -- URL source to retrieve Gems from.
  #
  # See PackageManager#install
  def install(*packages)
    return _install_helper(*packages) do |list, opts|
      gem = opts[:gem] || self.gem

      # Why is the "gem" utility such a steaming pile of offal? Lameness include:
      # - Requires interactive input to install a package, with no way to prevent this
      # - Repeatedly updates indexes even when there's no reason to, and can't be told to stop
      # - Doesn't cache packages, insists on downloading them again
      # - Installs broken packages, often without giving any indication of failure
      # - Installs broken packages and leaves you to deal with the jagged pieces
      # - Sometimes fails through exit status, sometimes through output, but not both and not consistently
      # - Lacks a proper "is this package installed?" feature
      # - A nightmare to deal with if you want to install your own GEMHOME/GEMPATH

      # Example of an invalid gem that'll cause the failure I'm trying to avoid below:
      #   package_manager.install("sys-cpu", :with => :gem)

      # gem options:
      # -y : Include dependencies,
      # -E : use /usr/bin/env for installed executables; but only with >= 0.9.4
      cmd = "#{gem} install -y"
      cmd << " --no-ri" if opts[:ri] == false or opts[:docs] == false
      cmd << " --no-rdoc" if opts[:rdoc] == false or opts[:docs] == false
      cmd << " --source #{opts[:source]}" if opts[:source]
      cmd << " "+list.join(" ")
      cmd << " " << opts[:args] if opts[:args]
      cmd << " 2>&1"

      # XXX Try to warn the user that they won't see any output for a while
      log.info(PNOTE+"Installing Gems, this will take a while...") if writing? and not opts[:quiet]
      log.info(PEXEC+cmd)
      return true if preview?

      uninstall_needed = false
      begin
        require 'expect'
        require 'open4'
        exitstruct = Open4::popen4(cmd) do |pid, sin, sout, serr|
          $expect_verbose = opts[:quiet] ? false : true

          re_success=/Successfully installed/m
          re_missing=/Could not find.+in any repository/m
          re_select=/Select which gem to install.+>/m
          re_failed=/Gem files will remain.+for inspection/m
          re_refused=/Errno::ECONNREFUSED reading .+?\.gem/m
          re_all=/#{re_success}|#{re_missing}|#{re_select}|#{re_failed}|#{re_refused}/m

          while true
            begin
              captureded = sout.expect(re_all)
            rescue NoMethodError
              log.debug(PNOTE+"Gem quit without closing STDOUT")
              break
            end
            if captureded.nil?
              log.debug(PNOTE+"Gem quit without emitting STDOUT")
              break
            end
            ### puts "Captureded %s" % captureded.inspect
            captured = captureded.first
            if captured.match(re_failed)
              log.warn(PERROR+"Gem install failed mid-process")
              uninstall_needed = true
              break
            elsif captured.match(re_refused)
              log.warn(PERROR+"Gem install refused by server!\n#{captured}")
              break
            elsif captured.match(re_select)
              choice = captured.match(/^ (\d+)\. .+?\(ruby\)\s*$/)[1]
              log.info(PNOTE+"Guessing: #{choice}")
              sin.puts(choice)
            end
          end
        end
      rescue Errno::ENOENT => e
        raise NotImplementedError.new("can't find gem command: #{e}")
      end

      if uninstall_needed or not exitstruct.exitstatus.zero?
        log.error(PERROR+"Gem install failed, trying to uninstall broken pieces: #{list.inspect}")
        uninstall(list, opts)

        raise ArgumentError.new("Gem install failed because it's invalid, missing a dependency, or can't talk with Gem server: #{list.inspect}")
      end
    end
  end

  # See PackageManager#uninstall
  def uninstall(*packages)
    return _uninstall_helper(*packages) do |list, opts|
      gem = opts[:gem] || self.gem

      # TODO PackageManager::gem#uninstall -- add logic to handle prompts during removal
=begin
# idiotic program MAY prompt you like this on uninstall:

Gem 0.9.4 generates prompts like this:
** gem uninstall -x mongrel < /dev/null 2>&1

You have requested to uninstall the gem:
    mongrel-1.0.1
mongrel_cluster-1.0.2 depends on [mongrel (>= 1.0.1)]
If you remove this gems, one or more dependencies will not be met.
Continue with Uninstall? [Yn]  Successfully uninstalled mongrel version 1.0.1
Removing mongrel_rails

#-----------------------------------------------------------------------
Gem 0.9.0 generates prompts like this:
** gem uninstall -x mongrel < /dev/null 2>&1

Select RubyGem to uninstall:
1. mongrel-1.0.1
2. mongrel_cluster-1.0.2
3. All versions
> 3

You have requested to uninstall the gem:
    mongrel-1.0.1
mongrel_cluster-1.0.2 depends on [mongrel (>= 1.0.1)]
If you remove this gems, one or more dependencies will not be met.
Continue with Uninstall? [Yn]  y
Successfully uninstalled mongrel version 1.0.1
Successfully uninstalled mongrel_cluster version 1.0.2
root@ubuntu:/mnt/satori/svnwork/automateit/src/examples/myapp_rails#
=end
      for package in list
        # gem options:
        # -x : remove installed executables
        cmd = "#{gem} uninstall -x #{package} < /dev/null"
        cmd << " > /dev/null" if opts[:quiet]
        cmd << " 2>&1"
        interpreter.sh(cmd)
      end
    end
  end
end
