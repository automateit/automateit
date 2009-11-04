require 'erb'
require 'nested_error'

class HelpfulERB
  class Error < ::NestedError; end

  # ERB object
  attr_accessor :erb

  attr_accessor :lines_before

  attr_accessor :lines_after

  # Template filename
  attr_accessor :filename

  def initialize(text, filename=nil, opts={})
    @text = text
    @filename = filename
    @lines_before = opts[:before] || 5
    @lines_after = opts[:after] || 1

    @erb = ::ERB.new(@text, nil, '-')
    @erb.filename = @filename if @filename
  end

  def result(binder=nil)
    begin
      return @erb.result(binder)
    rescue Exception => e
      stack = caller 0
      for i in 0..e.backtrace.size
        l = e.backtrace[i]
        #puts "%s %s" % [i, l];
        break if l =~ /^([^:]+):(\d+):in `(render|result)'$/
      end
      template = $1
      line_number = $2.to_i
      raise Exception.new("Caught ERB error but couldn't find line number in backtrace:\n#{e.backtrace.join("\n")}") unless line_number

      lines = @text.split(/\n/)

      min = line_number - @lines_before
      min = 0 if min < 0

      max = line_number + @lines_after
      max = lines.size if max > lines.size

      width = max.to_s.size

      msg = "Problem with template '#{template}' at line #{line_number}:\n"
      for i in min..max
        n = i+1
        marker = n == line_number ? "*" : ""
        msg << "\n%2s %#{width}i %s" % [marker, n, lines[i]]
      end
      msg << "\n\n(#{e.exception.class}) #{e.message}"


      raise NestedError.new(msg, e)
    end
  end
end
