require 'automateit'

module AutomateIt
  # TemplateManager renders templates to files.
  class TemplateManager < Plugin::Manager
    alias_methods :render

    # See documentation for TemplateManager::ERB#render
    def render(source, target, opts={}) dispatch(source, target, opts) end

    # Renders ERB templates for TemplateManager.
    class ERB < Plugin::Driver
      require 'erb'

      # The default method for performing checks, e.g. :compare
      attr_accessor :default_check

      def setup(opts={})
        super(opts)
        @default_check = :compare
      end

      def suitability(method, *args)
        return 1
      end

      # Render +source+ filename to +target+ filename.
      #
      # Options hash may have a :check argument that determines when to render the target, otherwise it uses the value specified in #default_check:
      # * +compare+: Only render if rendered template is different than the target's contents or if the target doesn't exist.
      # * +timestamp+: Only render if the target is older than the template and dependencies.
      # * +exists+: Only render if the target doesn't exist.
      #
      # Options hash includes optional arguments:
      # * +locals+: Hash of variables passed to template as local variables.
      # * +dependencies+: When checking timestamps, include this Array of filenames when checking timestamps.
      # * +force+: Boolean to force rendering without checking timestamps.
      #
      # For example, if the file +my_template_file+ contains:
      #   Hello <%=entity%>!
      #
      # You could then execute:
      #   render("my_template_file", "/tmp/out", :check => :compare, :locals => {:entity => "world"})
      #
      # And this should create a <tt>/tmp/out</tt> file with:
      #   Hello world!
      def render(source_filename, target_filename, opts={})
        opts[:check] ||= @default_check
        target_exists = _exists?(target_filename)
        updates = []

        unless opts[:force]
          case opts[:check]
          when :exists
            if target_exists
              log.debug("### Rendering for '#{target_filename}' skipped because it already exists")
              return false
            end
          when :timestamp
            if target_exists
              updates = _newer(target_filename, \
                  *[source_filename, opts[:dependencies]].reject{|t| t.nil?}.flatten)
              if updates.empty?
                log.debug("### Rendering for '#{target_filename}' skipped because dependencies haven't been updated")
                return false
              end
            end
          end
        end

        target_contents = target_exists ? _read(target_filename) : ""
        source_contents = _read(source_filename)
        binder = nil
        if opts[:locals]
          # Create a binding that the template can get variables from without
          # polluting the Driver's namespace.
          binder = lambda{
            code = ""
            for key in opts[:locals].keys
              code << "#{key} = opts[:locals][:#{key}]\n"
            end
            eval code
            binding
          }.call
        end
        output = ::ERB.new(source_contents, nil, '-').result(binder)

        case opts[:check]
        when :compare
          if source_contents == target_contents
            log.debug("### Rendering for '#{target_filename}' skipped because contents are the same")
            return false
          else
            log.info("### Rendering '#{target_filename} because its contents changed")
          end
        when :timestamp
          log.info("### Rendering '#{target_filename}' because of updated: #{updates.join(' ')}")
        end
        return _write(target_filename, output)
      end

      protected

      # Return an Array of +dependencies+ newer than +filename+. Will be empty if +filename+ is newer than all of the +dependencies+.
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
        return File.read(filename)
      end

      # Write +contents+ to +filename+.
      def _write(filename, contents)
        return true if File.open(filename, "w+"){|writer| writer.write(contents)}
      end

      # Return the modification date for +filename+.
      def _mtime(filename)
        return File.mtime(filename)
      end
    end
  end
end
