# See AutomateIt::Interpreter for usage information.
module AutomateIt # :nodoc:
  # AutomateIt version
  VERSION=Gem::Version.new("0.0.1")

  # Instantiate an +Interpreter+.
  def self.new(*options)
    Interpreter.new(*options)
  end
end
