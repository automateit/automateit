require 'tmpdir'
require 'fileutils'

# == Tempster
#
# Tempster is a pure-Ruby library for creating temporary files and directories.
# Unlike other tools, it can create both temporary files and directories, and
# is designed to be secure, thread-safe, easy-to-use, powerful thanks to
# user-configurable options, and user-friendly thanks to good defaults so you
# don't need to provide any arguments.
#
# Why write another library for this? The Tempfile standard library provides no
# way to create temporary directories and always deletes the files it creates,
# even if you want to keep them. The MkTemp gem is insecure and fails on
# collisions. Linux "mktemp" works fine but is platform-specific. Therefore, I
# had to write something.
#
# === WARNING: Using 'cd' and :noop together can be dangerous!
#
# Tempster will only *pretend* to make directories in :noop (no-operation)
# mode. In :noop mode, it will also only *pretend* to change into the directory
# when using :cd or +mktempdircd+.
#
# This can be *disastrous* if you're executing non-AutomateIt commands (e.g.
# +system+) that use *relative* *paths* and expect to be run inside the
# newly-created temporary directory because the +chdir+ didn't actually happen.
#
# Read more on this issue and how to deal with it in the
# AutomateIt::ShellManager class documentation.
#
# == Credits
# * Random string generator taken from
#   http://pleac.sourceforge.net/pleac_ruby/numbers.html
class Tempster
  DEFAULT_NAME = "tempster"
  DEFAULT_FILE_MODE = 0600
  DEFAULT_DIRECTORY_MODE = 0700
  DEFAULT_ARMOR_LENGTH = 10
  ARMOR_CHARACTERS = ["A".."Z","a".."z","0".."9"].collect{|r| r.to_a}.join

  # Options:
  # * :name -- Name prefix to usse, defaults to "tempster".
  # * :kind -- Create a :file or :directory, required.
  # * :dir -- Base directory to create temporary entries in, uses system-wide temporary directory (e.g., <tt>/tmp</tt>) by default.
  # * :cd -- Change into the newly directory created using +ch+ within the block, and then switch back to the previous directory. Only used when a block is given and the :kind is :directory. Default is false. See WARNING at the top of this class's documentation!
  # * :noop -- no-operation mode, pretends to do actions without actually creating or deleting temporary entries. Default is false. WARNING: See WARNING at the top of this class's documentation!
  # * :verbose -- Print status messages about creating and deleting the temporary entries. Default is false.
  # * :delete -- Delete the temporary entries when exiting block. Default is true when given a block, false otherwise. If you don't use a block, you're responsible for deleting the entries yourself.
  # * :tries -- Number of tries to create a temporary entry, usually it'll succeed on the first try. Default is 10.
  # * :armor -- Length of armor to add to the name. These are random characters padding out the temporary entry names to prevent them from using existing files. If you have a very short armor, you're likely to get a collision and the algorithm will have to try again for the specified number of +tries+.
  # * :message_callback -- +lambda+ called when there's a message, e.g., <tt>lambda{|message| puts message}</tt>, regardless of :verbose state. By default :messaging is nil and messages are printed to STDOUT only when :verbose is true.
  # * :message_prefix -- String to put in front of messages, e.g., "# "
  def self._tempster(opts={}, &block)
    name = opts.delete(:name) || DEFAULT_NAME
    kind = opts.delete(:kind) or raise ArgumentError.new("'kind' option not specified")
    dir = opts.delete(:dir) || Dir.tmpdir
    cd = opts.delete(:cd) || false
    noop =  opts.delete(:noop) || false
    verbose = opts.delete(:verbose) || false
    delete = opts.delete(:delete) || block ? true : false
    tries = opts.delete(:tries) || 10
    armor = opts.delete(:armor) || DEFAULT_ARMOR_LENGTH
    message_callback = opts.delete(:message_callback) || nil
    message_prefix = opts.delete(:message_prefix) || ""
    mode = opts.delete(:mode) || \
      case kind
      when :file
        DEFAULT_FILE_MODE
      when :directory
        DEFAULT_DIRECTORY_MODE
      else
        raise ArgumentError.new("unknown kind: #{kind}")
      end

    raise ArgumentError.new("can only use 'delete' option with block") if delete and not block
    raise ArgumentError.new("can only use 'cd' with directories and blocks") if cd and (not dir or not block)
    raise ArgumentError.new("unknown extra options: #{opts.inspect}") unless opts.empty?

    messager = Messager.new(verbose, message_callback, message_prefix)

    path = nil
    success = false
    for i in 1..tries
      begin
        path = File.join(dir, name+"_"+_armor_string(armor))
        unless noop
          case kind
          when :file
            File.open(path, File::RDWR|File::CREAT|File::EXCL).close
            File.chmod(mode, path)
          when :directory
            Dir.mkdir(path, mode)
          else
            raise ArgumentError.new("unknown kind: #{kind}")
          end
        end
        # XXX Should we pretend that it's mktemp? Or give users something more useful?
        # messager.puts("mktemp -m 0%o%s -p %s %s # => %s" % [mode, kind == :directory ? ' -d' : '', dir, name, path])
        if block
          messager.puts("mktempster --mode=0%o --kind=%s --dir=%s --name=%s" % [mode, kind, dir, name])
        else
          messager.puts("mktempster --mode=0%o --kind=%s --dir=%s --name=%s # => %s" % [mode, kind, dir, name, path])
        end
        success = true
        break
      rescue Errno::EEXIST
        # Try again
      end
    end
    raise IOError.new("couldn't create temporary #{kind}, ") unless success
    if block
      previous = Dir.pwd if cd
      begin
        if cd
          Dir.chdir(path) unless noop
          messager.puts("pushd #{path}")
        end
        block.call(path)
      rescue Exception => e
        # Re-throw exception after cleaning up
        raise e
      ensure
        if cd
          Dir.chdir(previous) unless noop
          messager.puts("popd # => #{previous}")
        end
        if delete
          FileUtils.rm_rf(path) unless noop
          messager.puts("rm -rf #{path}")
        end
      end
      return true
    else
      return path
    end
  end

  # Returns a string of random characters.
  def self._armor_string(length=DEFAULT_ARMOR_LENGTH)
    (1..length).collect{ARMOR_CHARACTERS[rand(ARMOR_CHARACTERS.size)]}.pack("C*")
  end

  # Creates a temporary file.
  def self.mktemp(opts={}, &block)
    _tempster({:kind => :file}.merge(opts), &block)
  end

  # Creates a temporary directory.
  #
  # WARNING: See WARNING at the top of this class's documentation!
  def self.mktempdir(opts={}, &block)
    _tempster({:kind => :directory}.merge(opts), &block)

  end

  # Creates a temporary directory and changes into it using +chdir+. This is a
  # shortcut for using +mktempdir+ with the <tt>:cd => true</tt> option.
  #
  # WARNING: See WARNING at the top of this class's documentation!
  def self.mktempdircd(opts={}, &block)
    _tempster({:kind => :directory, :cd => true}.merge(opts), &block)
  end

  class Messager
    def initialize(verbose, callback=nil, prefix="")
      @verbose = verbose
      @callback = callback
      @prefix = prefix
    end

    def puts(message)
      if @callback
        @callback.call(@prefix+message)
      else
        if @verbose
          STDOUT.puts @prefix+message
        end
      end
    end
  end
end

if __FILE__ == $0
  # TODO Tempster -- write a spec

  # Show a temp file created
  x = Tempster.mktemp(:verbose => true)
  File.stat(x)
  File.unlink(x)

  # Show a temp directory created
  x = Tempster.mktempdir(:verbose => true)
  File.directory?(x)
  FileUtils.rm_r(x)

  # Show a temp file created and removed with block
  path = nil
  Tempster.mktemp(:verbose => true) do |file|
    path = file
    puts file
  end
  begin
    File.unlink(path)
    raise "temporary file wasn't deleted when block ended: #{path}"
  rescue Errno::ENOENT
    # Expect the error
  end

  # Show temp directory created and removed with block
  path = nil
  Tempster.mktempdir(:verbose => true) do |dir|
    puts dir
    path = dir
    puts File.directory?(path)
  end
  puts File.directory?(path)

  # Show temp directory created and removed with block and cd
  path = nil
  Tempster.mktempdircd(:verbose => true) do |dir|
    path = dir
    puts "block's arg: "+dir
    puts "block's pwd: "+Dir.pwd
    puts "block's dir exists?: %s" % File.directory?(path)
  end
  puts "after dir exists?: %s" % File.directory?(path)
  puts "after pwd: "+Dir.pwd

  # Same with message callback
  path = nil
  Tempster.mktempdircd(:message_callback => lambda{|message| puts "$$$ "+message}) do |dir|
    path = dir
    puts "block's arg: "+dir
    puts "block's pwd: "+Dir.pwd
    puts "block's dir exists?: %s" % File.directory?(path)
  end
  puts "after dir exists?: %s" % File.directory?(path)
  puts "after pwd: "+Dir.pwd
end
