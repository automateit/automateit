# See AutomateIt::Interpreter for usage information.
module AutomateIt # :nodoc:
  # AutomateIt version
  VERSION=Gem::Version.new("0.80624")

  # Instantiates a new Interpreter. See documentation for
  # Interpreter#setup.
  def self.new(opts={})
    Interpreter.new(opts)
  end

  # Invokes an Interpreter on the recipe. See documentation for
  # Interpreter::invoke.
  def self.invoke(recipe, opts={})
    Interpreter.invoke(recipe, opts)
  end
end
