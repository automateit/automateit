# == TemplateManager::BaseDriver
#
# Base class for all TemplateManager drivers.
class AutomateIt::TemplateManager::BaseDriver < AutomateIt::Plugin::Driver
  # Name of default algorithm for performing checks, e.g., :compare
  attr_accessor :default_check

  # Options:
  # * :default_check - Set the #default_check, e.g., :compare
  def setup(opts={})
    super(opts)
    if opts[:default_check]
      @default_check = opts[:default_check]
    else
      @default_check ||= :compare
    end
  end

  #.......................................................................

protected

  # Return Array of +dependencies+ newer than +filename+. Will be empty if
  # +filename+ is newer than all of the +dependencies+.
  def _newer(filename, *dependencies)
    updated = []
    timestamp = _mtime(filename)
    for dependency in dependencies
      updated << dependency if _mtime(dependency) > timestamp
    end
    return updated
  end

  # Does +filename+ exist?
  def _exists?(filename)
    return File.exists?(filename)
  end

  # Return the contents of +filename+.
  def _read(filename)
    begin
      result = File.read(filename)
      return result
    rescue Errno::ENOENT => e
      if writing?
        raise e
      else
        return ""
      end
    end
  end

  # Write +contents+ to +filename+.
  def _write(filename, contents)
    File.open(filename, "w+"){|writer| writer.write(contents)} if writing?
    return true
  end

  # Backup +filename+.
  def _backup(filename)
    interpreter.backup(filename)
  end

  # Return the modification date for +filename+.
  def _mtime(filename)
    return _exists? ? File.mtime(filename) : nil
  end

  # Render a template specified in the block. It takes the same arguments and
  # returns the same results as the #render call.
  #
  # This method is used by the #render methods for different template drivers
  # and provides all the logic for parsing arguments, figuring out if a
  # template should be rendered, what to do with the rendering, etc.
  #
  # This method calls the supplied +block+ with a hash containing:
  # * :text -- Template's text.
  # * :filename -- Template's filename, or nil if none. The template
  # * :binder -- Binding containing the locals as variables.
  # * :locals -- Hash of locals.
  # * :opts -- Hash of options passed to the #_render_helper.
  #
  # The supplied block must return the text of the rendered template.
  #
  # See the TemplateManager::ERB#render method for a usage example.
  def _render_helper(*options, &block) # :yields: block_opts
    args, opts = args_and_opts(*options)
    source_filename = args[0] || opts[:file]
    target_filename = args[1] || opts[:to]
    source_text = opts[:text]
    opts[:backup] = true if opts[:backup].nil?

    raise ArgumentError.new("No source specified with :file or :text") if not source_filename and not source_text
    raise Errno::ENOENT.new(source_filename) if writing? and source_filename and not _exists?(source_filename)

    begin
      # source_filename, target_filename, opts={}
      opts[:check] ||= @default_check
      target_exists = target_filename && _exists?(target_filename)
      updates = []

      unless opts[:force]
        case opts[:check]
        when :exists
          if target_exists
            log.debug(PNOTE+"Rendering for '#{target_filename}' skipped because it already exists")
            return false
          else
            log.info(PNOTE+"Rendering '#{target_filename}' because of it doesn't exist")
          end
        when :timestamp
          if target_exists
            updates = _newer(target_filename, \
                *[source_filename, opts[:dependencies]].reject{|t| t.nil?}.flatten)
            if updates.empty?
              log.debug(PNOTE+"Rendering for '#{target_filename}' skipped because dependencies haven't been updated")
              return false
            end
          end
        end
      end

      target_contents = target_exists ? _read(target_filename) : ""
      source_text ||= _read(source_filename)

      if source_text.blank? and preview?
        return true
      end

      binder = nil
      if opts[:locals]
        # Create a binding that the template can get variables from without
        # polluting the Driver's namespace.
        callback = lambda{
          code = ""
          for key in opts[:locals].keys
            code << "#{key} = opts[:locals][:#{key}]\n"
          end
          eval code
          binding
        }
        binder = callback.call
      end

      block_opts = {
        :binder => binder,
        :filename => source_filename,
        :text => source_text,
        :locals => opts[:locals],
        :opts => opts,
      }
      output = block.call(block_opts)

      case opts[:check]
      when :compare
        if not target_exists
          log.info(PNOTE+"Rendering '#{target_filename}' because of it doesn't exist")
        elsif output == target_contents
          log.debug(PNOTE+"Rendering for '#{target_filename}' skipped because contents are the same")
          return false
        else
          log.info(PNOTE+"Rendering '#{target_filename}' because its contents changed")
        end
      when :timestamp
        log.info(PNOTE+"Rendering '#{target_filename}' because of updated: #{updates.join(' ')}")
      end

      _backup(target_filename) if target_exists and opts[:backup]

      return(target_filename ? _write(target_filename, output) : output)
    ensure
      if opts[:mode] or opts[:user] or opts[:group]
        interpreter.chperm(target_filename, :mode => opts[:mode], :user => opts[:user], :group => opts[:group])
      end
    end
  end
end
