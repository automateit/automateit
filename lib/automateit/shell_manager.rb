# == ShellManager
#
# The ShellManager provides Unix-like shell commands for manipulating files and
# executing commands.
#
# === WARNING: Previewing custom code can be dangerous!
#
# AutomateIt provides a way to preview commands without actually running them.
# The USAGE.txt[link:files/USAGE_txt.html] describes the basic concepts and use
# of preview when used with ShellCommands.
#
# However, AutomateIt only provides previewing logic for its own commands.
# Recipe authors are responsible for providing previewing logic for their own
# custom code.
#
# Here's what not to do with previews:
#
#   puts "Hello!"
#
# The above +puts+ method will execute in both preview (noop) and non-preview
# (writing) modes. To execute custom code only in a specific mode, wrap it with
# conditionals.
#
# For example:
#
#  if noop?
#    puts "This is a preview"
#  end
#
#  writing?("PREVIEW: Will run custom commands") do
#    puts "Custom commands"
#  end
#
# When run normally (#writing?), the above recipe displays:
#
#  Custom commands
#
# And when in preview mode (#noop?):
#
#  This is a preview
#  => PREVIEW: Will run custom commands
#
# Therefore, wrap all non-AutomateIt commands (e.g. +system+) that shouldn't be
# executed during the preview with conditionals.
#
# === WARNING: Changing directories during preview can be dangerous!
#
# AutomateIt will only *pretend* to make directories in preview mode. In
# preview mode, it will also only *pretend* to change into non-existent
# directories when using commands like #cd, #mkdir and #mktempdircd.
#
# This can be *disastrous* if you're executing non-AutomateIt commands (e.g.
# +system+) that use *relative* *paths* and expect to be run inside the
# newly-created temporary directory because the +chdir+ didn't actually happen.
#
# For example:
#
#   # DON'T EVER DO THIS!!!
#   mkdir_p "/tmp/foo/bar" do
#     system "echo 'I'm going to do: rm -rf *'"
#   end
#
# If that directory didn't already exist, then running the above code in
# preview mode would cause the +system+ command to actually run! If that wasn't
# an +echo+ command, it would have deleted the contents of your *current*
# directory -- not the <tt>/tmp/foo/bar</tt> directory -- because that
# directory wasn't actually created due to the preview mode!
#
# The correct way to write the above example is:
#
#   mkdir_p "/tmp/foo/bar" do
#     writing?("PREVIEW: Deleting all files in directory /tmp/foo/bar") do
#       system "echo 'I'm going to do: rm -rf *'"
#     end
#   end
#
# The Interpreter#writing? method ensures the +system+ command is only run when
# writing. When running in preview mode, that block will display only the
# message and won't actually execute the +system+ command:
#
#   => PREVIEW: Deleting all files in directory /tmp/foo/bar
#
# Without preview mode, AutomateIt will raise an exception when told to change
# into a non-existent directory. However, pretend to change directories without
# raising exceptions is necessary for preview mode to function properly.
class AutomateIt::ShellManager < AutomateIt::Plugin::Manager
  alias_methods :sh, :which, :which!, :mktemp, :mktempdir, :mktempdircd, :chperm, :umask
  alias_methods :cd, :pwd, :mkdir, :mkdir_p, :rmdir, :ln, :ln_s, :ln_sf, :cp, :cp_r, :cp_R, :mv, :rm, :rm_r, :rm_rf, :install, :chmod, :chmod_R, :chown, :chown_R, :touch

  #...[ Detection commands ]..............................................
  def provides_mode?() dispatch() end

  def provides_ownership?() dispatch() end

  def provides_symlink?() dispatch() end

  def provides_hard_link?() dispatch() end

  #...[ Custom commands ].................................................

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
  # CAUTION: Read notes at the top of ShellManager for potentially
  # problematic situations that may be encountered if using this command in
  # preview mode!
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
  # CAUTION: Read notes at the top of ShellManager for potentially
  # problematic situations that may be encountered if using this command in
  # preview mode!
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
  # CAUTION: Read notes at the top of ShellManager for potentially
  # problematic situations that may be encountered if using this command in
  # preview mode!
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
  # * :preserve -- preserve file modification time and ownership, boolean.
  # * :recursive -- copy files and directories recursively, boolean.
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
  def touch(targets) dispatch(targets) end
end

# == ShellManager::BaseDriver
#
# Base class for all ShellManager drivers.
class AutomateIt::ShellManager::BaseDriver < AutomateIt::Plugin::Driver
end

# Drivers
require 'automateit/shell_manager/portable'
require 'automateit/shell_manager/unix'
