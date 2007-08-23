require 'automateit'

module AutomateIt

  # EditManager provides a way of editing files and strings.
  class EditManager < Plugin::Manager

    alias_methods :edit

    # See documentation for EditSession::edit
    def edit(opts, &block) dispatch(opts, &block) end

    #-----------------------------------------------------------------------

    # Provides a way to edit files and strings. See documentation for EditSession.
    class Basic < Plugin::Driver

      def available?
        true
      end

      def suitability(method, *args)
        1
      end

      # See documentation for EditSession::edit
      def edit(opts, &block)
        EditSession.new(:interpreter => @interpreter).edit(opts, &block)
      end

      #-----------------------------------------------------------------------

      class EditSession < AutomateIt::Common
        # Edit a file or string. You must specify either the :file or :string
        # options.
        #
        # Options:
        # * :file - File to edit.
        # * :string - String to edit.
        # * :params - Hash to make available to editor session. Optional.
        #
        # Example:
        #   EditSession.edit(:file => "myfile", :params => {:hello => "world"} do
        #     prepend "myheader"
        #     append "yo "+params[:hello]
        #   end
        def edit(opts, &block)
          @filename = opts.delete(:file)
          @contents = opts.delete(:string)
          @params = opts.delete(:params) || {}
          @comment_prefix = "# "
          @comment_suffix = ""
          @contents ||= read || ""
          @original_contents = @contents.clone

          raise ArgumentError.new("no block given") unless block
          instance_eval(&block)
          if @filename
            write if different?
            return different?
          else
            return contents
          end
        end

        attr_accessor :filename
        attr_accessor :contents
        attr_accessor :original_contents
        attr_accessor :params
        attr_accessor :comment_prefix
        attr_accessor :comment_suffix

        # Prepend +line+ to the top of the buffer, but only if it's not in this
        # file already.
        #
        # Options:
        # * :unless - Look for this String or Regexp instead and don't prepend
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
          return if contains?(query)
          @contents = "%s\n%s" % [line, @contents]
        end

        # Append +line+ to the bottom of the buffer, but only if it's not in
        # this file already.
        #
        # Options:
        # * :unless - Look for this String or Regexp instead and don't append
        #   if it matches.
        #
        # See example for #prepend.
        def append(line, opts={})
          query = Regexp.new(opts[:unless] || line)
          return if contains?(query)
          @contents = "%s\n%s" % [@contents.chomp, line]
        end

        # Does the buffer contain anything that matches the String or Regexp +query+?
        def contains?(query)
          query = Regexp.new(query) unless Regexp === query
          ! @contents.match(query).nil?
        end

        # Delete lines matching the String or Regexp +query+
        def delete(query, opts={})
          query = Regexp.new(query+"\n?")
          @contents.gsub!(query, "")
        end

        # Specify the comment style's +prefix+ and +suffix+. Example:
        #
        #   # C style comments
        #   comment_style "/*", "*/"
        def comment_style(prefix, suffix="")
          @comment_prefix = prefix
          @comment_suffix = suffix
        end

        # Comment out lines matching the String or Regexp +query+.
        def comment(query, opts={})
          query = Regexp.new("^([^\n]*%s[^\n]*)(\n*)" % query)
          return false unless @contents.match(query)
          @contents.gsub!(query, "%s%s%s%s" % [@comment_prefix, $1, @comment_suffix, $2])
        end

        # Uncomment lines matching the String or Regexp +query+.
        def uncomment(query, opts={})
          query = Regexp.new("^(%s)([^\n]*%s[^\n]*)(%s)(\n*)" % [@comment_prefix, query, @comment_suffix])
          return false unless @contents.match(query)
          @contents.gsub!(query, "%s%s" % [$2, $4])
        end

        # Replace contents matching the String or Regexp +query+ with the +string+.
        def replace(query, string, opts={})
          query = Regexp.new(query)
          @contents.gsub!(query, string)
        end

        # Manipulate the buffer. The result of your block will replace the
        # buffer. This is very useful for complex edits. Example:
        #
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

        # Read contents from +filename+.
        def read
          @contents = \
            if writing? or (noop? and @filename and File.exists?(@filename))
              File.read(@filename)
            else
              nil
            end
        end

        # Write contents to +filename+.
        def write
          if writing?
            File.open(@filename, "w+"){|writer| writer.write(@contents)}
          else
            true
          end
        end
      end # class EditSession

    end # class Base
  end # class EditManager
end # module AutomateIt
