require 'automateit'

module AutomateIt

  # EditManager provides a way of editing files and strings.
  class EditManager < Plugin::Manager

    alias_methods :edit

    # Edit a file or string. You must specify either the :file or :string
    # options. Options:
    # * :file - File to edit.
    # * :string - String to edit.
    # * :params - Hash to make available to editor session. Optional.
    def edit(opts, &block) dispatch(opts, &block) end

    class Base < Plugin::Driver

      def available?
        true
      end

      def suitability(method, *args)
        1
      end

      def edit(opts, &block)
        EditSession.edit(opts, &block)
      end

      class EditSession
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

        def prepend(line, opts={})
          return if contains?(line)
          @contents = "%s\n%s" % [line, @contents]
        end

        def append(line, opts={})
          return if contains?(line)
          @contents = "%s\n%s" % [@contents.chomp, line]
        end

        def contains?(query)
          query = Regexp.new(query) unless Regexp === query
          ! @contents.match(query).nil?
        end

        def delete(query, opts={})
          query = Regexp.new(query+"\n?") unless Regexp === query
          @contents.gsub!(query, "")
        end

        def comment_style(prefix, suffix="")
          @comment_prefix = prefix
          @comment_suffix = suffix
        end

        def comment(query, opts={})
          query = Regexp.new("^([^\n]*%s[^\n]*)(\n*)" % query) unless Regexp === query
          return false unless @contents.match(query)
          @contents.gsub!(query, "%s%s%s%s" % [@comment_prefix, $1, @comment_suffix, $2])
        end

        def uncomment(query, opts={})
          query = Regexp.new("^(%s)([^\n]*%s[^\n]*)(%s)(\n*)" % [@comment_prefix, query, @comment_suffix]) unless Regexp === query
          return false unless @contents.match(query)
          @contents.gsub!(query, "%s%s" % [$2, $4])
        end

        def replace(query, string, opts={})
          query = Regexp.new(query) unless Regexp === query
          @contents.gsub!(query, string)
        end

        def manipulate(&block)
          @contents = block.call(@contents)
        end

        def different?
          @contents != @original_contents
        end

        def read
          @contents = File.read(@filename)
        end

        def write
          File.open(@filename, "w+"){|writer| writer.write(@contents)}
        end
      end # class EditSession

    end # class Base
  end # class EditManager
end # module AutomateIt
