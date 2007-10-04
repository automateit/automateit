# == ShellManager
#
# The ShellManager provides Unix-like shell commands for manipulating files and
# executing commands.
#
# *WARNING*: Previewing code can be dangerous. Read
# previews.txt[link:files/docs/previews_txt.html] for instructions on how to
# write code that can be safely previewed.
class AutomateIt::ShellManager < AutomateIt::Plugin::Manager
  alias_methods :backup, :sh, :which, :which!, :mktemp, :mktempdir, :mktempdircd, :chperm, :umask
  alias_methods :cd, :pwd, :mkdir, :mkdir_p, :rmdir, :ln, :ln_s, :ln_sf, :cp, :cp_r, :cp_R, :mv, :rm, :rm_r, :rm_rf, :install, :chmod, :chmod_R, :chown, :chown_R, :touch

  #...[ Detection commands ]..............................................

  # See ShellManager#provides_mode?
  def provides_mode?() dispatch_safely end

  # See ShellManager#provides_mode?
  def provides_ownership?() dispatch_safely end

  # See ShellManager#provides_mode?
  def provides_symlink?() dispatch_safely end

  # See ShellManager#provides_mode?
  def provides_link?() dispatch_safely end

  #...[ Custom commands ].................................................

  # Backup +sources+ if they exist. Returns the names of the backups created.
  #
  # These backups are copies of the original sources saved into the same
  # directories as the originals. The pathnames of these copies are timestamped
  # and guaranteed to be unique, so you can have multiple backups of the same
  # sources.
  #
  # *WARNING*: This method is not conditional. It will make a backup every time
  # it's called if the sources exist. Therefore, only execute this method when
  # its needed.
  #
  # For example, backup a file:
  #
  #   backup("/tmp/myfile") # => "/tmp/myfile.1190994237_M2xhLrC6Sj.bak
  #
  # In the above example, the backup's name contains two special strings. The
  # "1190994237" is the time the backup was made in seconds since the Epoch.
  # The "M2xhLrC6Sj" is a random string used to guarantee the uniqueness of
  # this backup in case two are made at exactly the same time.
  def backup(*sources) dispatch(*sources) end

  # Execute a shell command.
  def sh(*commands) dispatch(*commands) end

  # What is the path for this command? Returns +nil+ if command isn't found.
  #
  # Example:
  #   which("ls") # => "/bin/ls"
  def which(command) dispatch(command) end

  # Same as #which but throws an ArgumentError if command isn't found.
  def which!(command) dispatch(command) end

  # Creates a temporary file. Optionally takes a +name+ argument which is
  # purely cosmetic, e.g., if the +name+ is "foo", the routine may create a
  # temporary file named <tt>/tmp/foo_qeKo7nJk1s</tt>.
  #
  # When called with a block, invokes the block with the path of the temporary
  # file and deletes the file at the end of the block.
  #
  # Without a block, returns the path of the temporary file and you're
  # responsible for removing it when done.
  def mktemp(name=nil, &block) # :yields: path
    dispatch(name, &block)
  end

  # Creates a temporary directory. See #mktemp for details on the +name+
  # argument.
  #
  # When called with a block, invokes the block with the path of the
  # temporary directory and recursively deletes the directory and its
  # contents at the end of the block.
  #
  # Without a block, returns the path of the temporary directory and you're
  # responsible for removing it when done.
  #
  # CAUTION: Read notes at the top of ShellManager for potentially
  # problematic situations that may be encountered if using this command in
  # preview mode!
  def mktempdir(name=nil, &block) # :yields: path
    dispatch(name, &block)
  end

  # Same as #mktempdir but performs a #cd into the directory for the duration
  # of the block.
  #
  # Example:
  #
  #   puts pwd # => "/home/bubba"
  #   mktempdircd do |path|
  #     puts path # => "/tmp/tempster_qeKo7nJk1s"
  #     puts pwd  # => "/tmp/tempster_qeKo7nJk1s"
  #   end
  #   puts File.exists?("/tmp/tempster_qeKo7nJk1s") # => false
  def mktempdircd(name=nil, &block) # :yields: path
    dispatch(name, &block)
  end

  # Change the permissions of the +targets+. This command is like the #chmod
  # and #chown in a single command.
  #
  # Options:
  # * :recursive -- Change files and directories recursively. Defaults to false.
  # * :user -- User name to change ownership to.
  # * :group -- Group name to change ownership to.
  # * :mode -- Mode to use as octal, e.g., <tt>0400</tt> to make a file
  #   readable only to its owner.
  # * :details -- Reports the files modified, rather than the arguments
  #   modified. An argument might be a single directory, but this may result in
  #   modifications to many files within that directory. Use :details for
  #   situations when there's a need to see all files actually changed. The
  #   reason :details is off by default is that it will flood the screen with a
  #   list of all files modified in a large directory, which is overwhelming
  #   and probably unnecessary unless you actually need to see these details.
  #   Defaults to false.
  def chperm(targets, opts={}) dispatch(targets, opts) end

  # Set the umask to +mode+. If given a block, changes the umask only for the
  # duration of the block and changes it back to its previous setting at the
  # end.
  def umask(mode=nil, &block) dispatch(mode, &block) end

  #...[ FileUtils wrappers ]...............................................

  # Changes the directory into the specified +dir+. If called with a block,
  # changes to the directory for the duration of the block, and then changes
  # back to the previous directory at the end.
  #
  # *WARNING*: Previewing code can be dangerous. Read
  # previews.txt[link:files/docs/previews_txt.html] for instructions on how to
  # write code that can be safely previewed.
  def cd(dir, opts={}, &block) dispatch(dir, opts, &block) end

  # Returns the current directory.
  def pwd() dispatch() end

  # Create a directory or directories. Returns an array of directories
  # created or +false+ if all directories are already present.
  #
  # Options:
  # * :parents -- Create parents, like "mkdir -p". Boolean.
  # * :mode, :user, :group -- See #chperm
  #
  # *WARNING*: Previewing code can be dangerous. Read
  # previews.txt[link:files/docs/previews_txt.html] for instructions on how to
  # write code that can be safely previewed.
  def mkdir(dirs, opts={}, &block) dispatch(dirs, &block) end

  # Create a directory or directories with their parents. Returns an array of
  # directories created or +false+ if all directories are already present.
  #
  # Options same as #mkdir.
  #
  # Example:
  #   File.exists?("/tmp/foo") # => false
  #   mkdir_p("/tmp/foo/bar")
  #   File.exists?("/tmp/foo") # => true
  #   File.exists?("/tmp/foo/bar") # => true
  #
  # *WARNING*: Previewing code can be dangerous. Read
  # previews.txt[link:files/docs/previews_txt.html] for instructions on how to
  # write code that can be safely previewed.
  def mkdir_p(dirs, opts={}, &block) dispatch(dirs, &block) end

  # Remove a directory or directories. The directories must be empty or an
  # exception is thrown. Returns the directories removed or +false+ if none
  # of the directories exist.
  def rmdir(dirs) dispatch(dirs) end

  # Create a hard link between the +source+ and +target+. Your platform must
  # support hard links to use this. Returns the target created or +false+ if
  # the link is already present.
  def ln(source, target, opts={}) dispatch(source, target, opts) end

  # Create a symbolic link between the +sources+ and +target+. Your platform
  # must support symbolic links to use this. Returns an array of sources
  # linked or +false+ if all are already present.
  def ln_s(sources, target, opts={}) dispatch(sources, target, opts) end

  # Create a symbolic link between the +sources+ and +target+. If the
  # +target+ already exists, will remove it and recreate it. Your platform
  # must support symbolic links to use this. Returns an array of sources
  # linked or +false+ if all are already present.
  def ln_sf(sources, target, opts={}) dispatch(sources, target, opts) end

  # Copy the +sources+ to the +target+. Returns an array of sources copied or
  # +false+ if all are present.
  #
  # Options:
  # * :preserve -- Preserve file modification time and ownership. Defaults to
  #   false. Can be +true+, +false+, or :try. If :try, the properties will be
  #   preserved if possible on the platform, whereas +true+ will raise an
  #   exception if not available.
  # * :recursive -- Copy files and directories recursively, boolean.
  def cp(sources, target, opts={}) dispatch(sources, target, opts) end

  # Copy the +sources+ to the +target+ recursively. Returns an array of
  # sources copied or +false+ if all are present.
  def cp_r(sources, target, opts={}) dispatch(sources, target, opts) end

  # Copy the +sources+ to the +target+ recursively. Returns an array of
  # sources copied or +false+ if all are present.
  def cp_R(sources, target, opts={}) dispatch(sources, target, opts) end

  # Move the +sources+ to the +target+. Returns an array of sources copied or
  # +false+ if none of the sources exist.
  def mv(sources, target) dispatch(sources, target) end

  # Remove the +targets+. Returns a list of targets removed or +false+ if
  # none of them exist.
  def rm(targets, opts={}) dispatch(targets, opts) end

  # Remove the +targets+ recursively. Returns a list of targets removed or
  # +false+ if none of them exist.
  def rm_r(targets, opts={}) dispatch(targets, opts) end

  # Remove the +targets+ recursively and forcefully. Returns a list of
  # targets removed or +false+ if none of them exist.
  def rm_rf(targets, opts={}) dispatch(targets, opts) end

  # Copy the +source+ to the +target+ and set its +mode+. Returns true if the
  # file was installed or +false+ if already present.
  def install(source, target, mode) dispatch(source, target, mode) end

  # Change the permission +mode+ of the +targets+. Returns an array of
  # targets modified or +false+ if all have the desired mode.
  def chmod(mode, targets, opts={}) dispatch(mode, targets, opts) end

  # Change the permission +mode+ of the +targets+ recursively. Returns an
  # array of targets modified or +false+ if all have the desired mode.
  def chmod_R(mode, targets, opts={}) dispatch(mode, targets, opts) end

  # Change the +user+ and +group+ ownership of the +targets+. You can leave
  # either the user or group as nil if you don't want to change it. Returns
  # an array of targets modified or +false+ if all have the desired
  # ownership.
  def chown(user, group, targets, opts={}) dispatch(user, group, targets, opts) end

  # Change the +user+ and +group+ ownership of the +targets+ recursively. You
  # can leave either the user or group as nil if you don't want to change it.
  # Returns an array of targets modified or +false+ if all have the desired
  # ownership.
  def chown_R(user, group, targets, opts={}) dispatch(user, group, targets, opts) end

  # Create the +targets+ as files if needed and update their modification
  # time. Unlike most other commands provided by ShellManager, this one will
  # always modify the targets. Returns an array of targets modified.
  #
  # Options:
  # * :like -- Touch the targets like this file. Defaults to none.
  # * :stamp -- Set the targets to the specified timestamp. Defaults to Time.now.
  def touch(targets, opts={}) dispatch(targets, opts) end
end

# == ShellManager::BaseDriver
#
# Base class for all ShellManager drivers.
class AutomateIt::ShellManager::BaseDriver < AutomateIt::Plugin::Driver
  def _replace_owner_with_user(opts)
    value = opts.delete(:owner)
    opts[:user] = value  if value and not opts[:user]
    return opts
  end
  protected :_replace_owner_with_user

  # Returns hash of verbosity and preview settings for FileUtils commands.
  def _fileutils_opts
    opts = {}
    opts[:verbose] = false # Generate our own log messages
    opts[:noop] = true if preview?
    return opts
  end
  protected :_fileutils_opts

  # Return array of all the directory's top-level contents, including hidden
  # files with "." prefix on UNIX. Directories are returned just as a name,
  # you'll need to expand those separately if needed.
  def _directory_contents(directory)
    return Dir[directory+"/{,.}*"].reject{|t| t =~ /(^|#{File::SEPARATOR})\.{1,2}$/}
  end
  protected :_directory_contents

  # Returns derived filename to use as a peer given the +source+ and +target+.
  # This is necessary for differentiating between directory and file targets.
  #
  # For example:
  #
  #   # Get the peer for an extant target directory:
  #   peer_for("foo", "/tmp") # => "/tmp/foo"
  #
  #   # Get the peer for anything else:
  #   peer_for("foo", "/bar") # => "/bar"
  def peer_for(source, target)
    return FileUtils.send(:fu_each_src_dest0, source, target){|a, b| b}
  end
end

# Drivers
require 'automateit/shell_manager/portable'
require 'automateit/shell_manager/which'
require 'automateit/shell_manager/base_link'
require 'automateit/shell_manager/symlink'
require 'automateit/shell_manager/link'
