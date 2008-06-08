class Object
  # Lists methods unique to an instance.
  def unique_methods
    (public_methods - Object.methods).sort.map(&:to_sym)
  end

  # Lists methods unique to a class.
  def self.unique_methods
    (public_methods - Object.methods).sort.map(&:to_sym)
  end

  # Returns a list of arguments and an options hash. Source taken from RSpec.
  def args_and_opts(*args)
    options = Hash === args.last ? args.pop : {}
    return args, options
  end
end

