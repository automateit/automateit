# Suraj Kurapati -- http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/261459
class String
  # Transforms this string into an escaped POSIX shell argument.
  def shell_escape
    inspect.gsub(/\\(\d{3})/) {$1.to_i(8).chr}
  end
end
