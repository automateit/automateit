require 'automateit'

module AutomateIt

  # EditManager provides a way of editing files and strings.
  class EditManager < Plugin::Manager

    alias_methods :edit

    # See documentation for EditSession::edit
    def edit(opts, &block) dispatch(opts, &block) end

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
        EditSession.edit(opts, &block)
      end

      class EditSession

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
        def self.edit(opts, &block)
          raise ArgumentError.new("no block given") unless block
          session = self.new(opts)
          session.instance_eval(&block)
          if session.filename
            session.write if session.different?
            return session.different?
          else
            return session.contents
          end
        end

        attr_accessor :filename
        attr_accessor :contents
        attr_accessor :original_contents
        attr_accessor :params
        attr_accessor :comment_prefix
        attr_accessor :comment_suffix

        def initialize(opts)
          @filename = opts[:file]
          @contents = opts[:string] or read
          @original_contents = @contents.clone
          @params = opts[:params] || {}
          @comment_prefix = "# "
          @comment_suffix = ""
        end

        # Prepend the +line+ to the top of the buffer, but only if it's not in this file already.
        def prepend(line, opts={})
          return if contains?(line)
          @contents = "%s\n%s" % [line, @contents]
        end

        # Append the +line+ to the bottom of the buffer, but only if it's not in this file already.
        def append(line, opts={})
          return if contains?(line)
          @contents = "%s\n%s" % [@contents.chomp, line]
        end

        # Does the buffer contain anything that matches the +query+?
        def contains?(query)
          query = Regexp.new(query) unless Regexp === query
          ! @contents.match(query).nil?
        end

        # Delete lines matching the +query+
        def delete(query, opts={})
          query = Regexp.new(query+"\n?") unless Regexp === query
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

        # Comment out lines matching the +query+.
        def comment(query, opts={})
          query = Regexp.new("^([^\n]*%s[^\n]*)(\n*)" % query) unless Regexp === query
          return false unless @contents.match(query)
          @contents.gsub!(query, "%s%s%s%s" % [@comment_prefix, $1, @comment_suffix, $2])
        end

        # Uncomment lines matching the +query+.
        def uncomment(query, opts={})
          query = Regexp.new("^(%s)([^\n]*%s[^\n]*)(%s)(\n*)" % [@comment_prefix, query, @comment_suffix]) unless Regexp === query
          return false unless @contents.match(query)
          @contents.gsub!(query, "%s%s" % [$2, $4])
        end

        # Replace contents matching the +query+ with the +string+.
        def replace(query, string, opts={})
          query = Regexp.new(query) unless Regexp === query
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
          @contents = File.read(@filename)
        end

        # Write contents to +filename+.
        def write
          File.open(@filename, "w+"){|writer| writer.write(@contents)}
        end
      end # class EditSession

    end # class Base
  end # class EditManager
end # module AutomateIt
