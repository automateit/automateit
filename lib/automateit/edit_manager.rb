# == EditManager
#
# The EditManager provides a way of editing files and strings
# programmatically.
#
# See documentation for EditManager::EditSession.
class AutomateIt::EditManager < AutomateIt::Plugin::Manager
  alias_methods :edit

  # Creates an editing session. See documentation for EditManager::EditSession.
  def edit(*opts, &block) dispatch(*opts, &block) end
end

# == EditManager::BaseDriver
#
# Base class for all EditManager drivers.
class AutomateIt::EditManager::BaseDriver < AutomateIt::Plugin::Driver
end

# == EditManager::Simple
#
# Provides a way to edit files and strings.
#
# See documentation for EditSession.
class AutomateIt::EditManager::Simple < AutomateIt::EditManager::BaseDriver
  depends_on :nothing

  def suitability(method, *args) # :nodoc:
    1
  end

  # Creates an editing session. See documentation for EditSession#edit.
  def edit(*opts, &block)
    AutomateIt::EditManager::EditSession.new(:interpreter => @interpreter).edit(*opts, &block)
  end
end # class Base

# == EditSession
#
# EditSession provides a way to edit files and strings.
#
# For example, here's how to edit a string from the Interpreter:
#
#   edit(:text => "# hello") do
#     uncomment "llo"
#     append "world"
#   end
#   # => "hello\nworld"
#
# The above example edits a text string containing "# hello". The editing
# session uncomments the line containing "llo" and then appends a line with the
# word "world". The edited result is returned, containing two lines: "hello"
# and "world".
#
# The edit session only makes changes if they're needed. In the above example,
# once the "hello" line is uncommented, the "uncomment" command won't do
# anything. Similarly, once the word "world" has been appended, it won't be
# appended again. So if you re-edit the resulting string, it won't be changed
# because it's already in the desired state.
#
# This approach simplifies editing because you only need to specify the
# commands that are needed to change the file, and the session will figure out
# which ones to run.
class AutomateIt::EditManager::EditSession < AutomateIt::Common
  # Create an EditSession.
  #
  # Options:
  # * :interpreter -- AutomateIt Interpreter, required. Will be automatically
  #   set if you use AutomateIt::Interpreter#edit.
  def initialize(*args)
    super(*args)
    interpreter.add_method_missing_to(self)
  end

  # Edit a file or string.
  #
  # Requires a filename argument or options hash -- e.g.,.
  # <tt>edit("foo")</tt> and <tt>edit(:file => "foo")</tt> will both edit a
  # file called +foo+.
  #
  # Options:
  # * :file -- File to edit.
  # * :text -- String to edit.
  # * :params -- Hash to make available to editor session.
  # * :create -- Create the file if it doesn't exist? Defaults to false.
  # * :mode, :user, :group -- Set permissions on generated file, see ShellManager#chperm
  # * :backup -- Make a backup of original file? Defaults to true.
  #
  # Edit a string:
  #
  #   edit(:text => "foo") do
  #     replace "o", "@"
  #   end
  #   # => "f@@"
  #
  # Edit a file and pass parameters to the editing session:
  #
  #   edit(:file => "myfile", :params => {:greet => "world"} do
  #     prepend "MyHeader"
  #     append "Hello "+params[:greet]
  #   end
  #
  # Edit a file, create it and set permissions if necessary:
  #
  #   edit("/tmp/foo", :create => true, :mode => 0600, :user => :root) do
  #     prepend "Hello world!"
  #   end
  def edit(*a, &block)
    args, opts = args_and_opts(*a)
    if args.first
      @filename = args.first
    else
      raise ArgumentError.new("no file or text specified for editing") unless opts[:file] or opts[:text]
      @filename = opts[:file]
      @contents = opts[:text]
    end
    @params = opts[:params] || {}
    @is_backup = opts[:backup].nil? ? true : opts[:backup]
    @comment_prefix = "# "
    @comment_suffix = ""
    begin
      @contents ||= _read || ""
    rescue Errno::ENOENT => e
      if opts[:create]
        @contents = ""
      else
        raise e
      end
    end
    @original_contents = @contents.clone

    raise ArgumentError.new("no block given") unless block
    instance_eval(&block)
    if @filename
      if different?
        _backup if @is_backup
        _write
      end

      chperm_opts = {}
      for key in [:owner, :user, :group, :mode]
        chperm_opts[key] = opts[key] if opts[key]
      end
      chperm(@filename, chperm_opts) unless chperm_opts.empty?

      return different?
    else
      return contents
    end
  end

  # File that was read for editing.
  attr_accessor :filename

  # Current contents of the editing buffer.
  attr_accessor :contents

  # Original contents of the editing buffer before any changes were made.
  attr_accessor :original_contents

  # Hash of parameters to make available to the editing session.
  attr_accessor :params

  # Comment prefix, e.g., "/*"
  attr_accessor :comment_prefix

  # Comment suffix, e.g., "*/"
  attr_accessor :comment_suffix

  # Prepend +line+ to the top of the buffer, but only if it's not in this
  # file already.
  #
  # Options:
  # * :unless -- Look for this String or Regexp instead and don't prepend
  #   if it matches.
  #
  # Example:
  #   # Buffer's contents are 'add    this line'
  #
  #   # This will prepend a line because they're not identical.
  #   prepend("add this line")
  #
  #   # Won't prepend line because Regexp matches exisint line in buffer.
  #   prepend("add this line", :unless => /add\s*this\*line/)
  def prepend(line, opts={})
    query = Regexp.new(opts[:unless] || line)
    query = Regexp.escape(query) if query.is_a?(String)
    return if contains?(query)
    @contents = "%s\n%s" % [line, @contents]
  end

  # Append +line+ to the bottom of the buffer, but only if it's not in
  # this file already.
  #
  # Options:
  # * :unless -- Look for this String or Regexp instead and don't append
  #   if it matches.
  #
  # See example for #prepend.
  def append(line, opts={})
    query = opts[:unless] || line
    if query.is_a?(String)
      query = Regexp.new(Regexp.escape(query))
    end
    return if contains?(query)
    @contents = "%s\n%s\n" % [@contents.chomp, line]
  end

  # Does the buffer contain anything that matches the String or Regexp +query+?
  def contains?(query)
    if query.is_a?(String)
      query = Regexp.new(Regexp.escape(query))
    end
    ! @contents.match(query).nil?
  end

  # Delete lines matching the String or Regexp +query+
  def delete(query, opts={})
    query = Regexp.escape(query) if query.is_a?(String)
    query = Regexp.new("^[^\n]*%s[^\n]*\n?" % query)
    @contents.gsub!(query, "")
  end

  # Specify the comment style's +prefix+ and +suffix+.
  #
  # Example:
  #   # C style comments
  #   comment_style "/*", "*/"
  def comment_style(prefix, suffix="")
    @comment_prefix = prefix
    @comment_suffix = suffix
  end

  # Comment out lines matching the String or Regexp +query+.
  def comment(query, opts={})
    query = Regexp.escape(query) if query.is_a?(String)
    query = Regexp.new("^([^\n]*%s[^\n]*)(\n*)" % query)
    return false unless @contents.match(query)
    @contents.gsub!(query, "%s%s%s%s" % [@comment_prefix, $1, @comment_suffix, $2])
  end

  # Uncomment lines matching the String or Regexp +query+.
  def uncomment(query, opts={})
    query = Regexp.escape(query) if query.is_a?(String)
    query = Regexp.new("^(%s)([^\n]*%s[^\n]*)(%s)(\n*)" % [@comment_prefix, query, @comment_suffix])
    return false unless @contents.match(query)
    @contents.gsub!(query, "%s%s" % [$2, $4])
  end

  # Replace contents matching the String or Regexp +query+ with the +string+.
  def replace(query, string, opts={})
    if query.is_a?(String)
      query = Regexp.new(Regexp.escape(query))
    end
    @contents.gsub!(query, string)
  end

  # Manipulate the buffer. The result of your block will replace the
  # buffer. This is very useful for complex edits.
  #
  # Example:
  #   manipulate do |buffer|
  #     buffer.gsub(/foo/, "bar")
  #   end
  def manipulate(&block) # :yields: buffer
    @contents = block.call(@contents)
  end

  # Is the buffer currently different than its original contents?
  def different?
    @contents != @original_contents
  end

  # Read contents from #filename. Called by the #edit command to load text
  # into the buffer.
  def _read
    @contents = \
      if writing? or (preview? and @filename and _exists?)
        File.read(@filename)
      else
        nil
      end
  end
  protected :_read

  # Write contents to #filename. Used by the #edit command to write the buffer
  # to a file.
  def _write
    return false unless @filename
    log.info(PNOTE+"Edited '#{@filename}'")
    if preview?
      true
    else
      File.open(@filename, "w+"){|writer| writer.write(@contents)}
    end
  end
  protected :_write

  # Backup the original file.
  def _backup
    return false unless @filename and File.exists?(@filename)
    result = nil
    log.silence(Logger::WARN) do
      result = backup(@filename)
    end
    log.debug(PNOTE+"Saved '#{@filename}' to '#{result}'")
  end
  protected :_backup

  # Does the file exist?
  def _exists?
    File.exists?(@filename)
  end
  protected :_exists?
end # class EditSession
