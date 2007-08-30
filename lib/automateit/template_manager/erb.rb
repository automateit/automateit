module AutomateIt
  class TemplateManager
    # == TemplateManager::ERB
    #
    # Renders ERB templates for TemplateManager.
    class ERB < Plugin::Driver
      require 'erb'

      # The default method for performing checks, e.g. :compare
      attr_accessor :default_check

      # Options:
      # * :default_check - Set the #default_check, e.g. :compare
      def setup(opts={})
        super(opts)
        if opts[:default_check]
          @default_check = opts[:default_check]
        else
          @default_check ||= :compare
        end
      end

      def available? # :nodoc:
        return true
      end

      def suitability(method, *args) # :nodoc:
        return 1
      end

      # Render +source+ filename to +target+ filename.
      #
      # Options:
      # * :locals -- Hash of variables passed to template as local variables.
      # * :dependencies -- When checking timestamps, include this Array of filenames when checking timestamps.
      # * :force -- Boolean to force rendering without checking timestamps.
      # * :check -- Determines when to render, otherwise uses value of +default_check+, possible values:
      #   * :compare -- Only render if rendered template is different than the target's contents or if the target doesn't exist.
      #   * :timestamp -- Only render if the target is older than the template and dependencies.
      #   * :exists -- Only render if the target doesn't exist.
      #
      # For example, if the file +my_template_file+ contains:
      #   Hello <%=entity%>!
      #
      # You could then execute:
      #   render("my_template_file", "/tmp/out", :check => :compare, :locals => {:entity => "world"})
      #
      # And this should create a <tt>/tmp/out</tt> file with:
      #   Hello world!
      def render(*options)
        args, opts = args_and_opts(*options)
        source_filename = args[0] || opts[:file]
        target_filename = args[1] || opts[:to]
        source_contents = opts[:text]

        begin
          # source_filename, target_filename, opts={}
          opts[:check] ||= @default_check
          target_exists = _exists?(target_filename)
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
          source_contents ||= _read(source_filename)
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
          output = ::ERB.new(source_contents, nil, '-').result(binder)

          case opts[:check]
          when :compare
            if not target_exists
              log.info(PNOTE+"Rendering '#{target_filename}' because of it doesn't exist")
            elsif source_contents == target_contents
              log.debug(PNOTE+"Rendering for '#{target_filename}' skipped because contents are the same")
              return false
            else
              log.info(PNOTE+"Rendering '#{target_filename} because its contents changed")
            end
          when :timestamp
            log.info(PNOTE+"Rendering '#{target_filename}' because of updated: #{updates.join(' ')}")
          end
          result = _write(target_filename, output)
          return result
        ensure
          if opts[:mode] or opts[:user] or opts[:group]
            interpreter.chperm(target_filename, :mode => opts[:mode], :user => opts[:user], :group => opts[:group])
          end
        end
      end

      # Return an Array of +dependencies+ newer than +filename+. Will be empty if +filename+ is newer than all of the +dependencies+.
      def _newer(filename, *dependencies)
        updated = []
        timestamp = _mtime(filename)
        for dependency in dependencies
          updated << dependency if _mtime(dependency) > timestamp
        end
        return updated
      end
      private :_newer

      # Does +filename+ exist?
      def _exists?(filename)
        return File.exists?(filename)
      end
      private :_exists?

      # Return the contents of +filename+.
      def _read(filename)
        return writing? ? File.read(filename) : ""
      end
      private :_read

      # Write +contents+ to +filename+.
      def _write(filename, contents)
        File.open(filename, "w+"){|writer| writer.write(contents)} if writing?
        return true
      end
      private :_write

      # Return the modification date for +filename+.
      def _mtime(filename)
        return _exists? ? File.mtime(filename) : nil
      end
      private :_mtime
    end
  end
end
