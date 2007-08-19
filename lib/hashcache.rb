# A very simple cache. Works just like a Hash, but can optionally store values
# during the fetch process.
#
# Example:
#   hc = HashCache.new
#   hc.fetch("foo")
#   => nil
#   hc.fetch("foo"){:bar} # Block gets called because 'foo' is nil
#   => :bar
#   hc.fetch("foo"){raise "Block won't be called because 'foo' is cached"}
#   => :bar
class HashCache < Hash
  def fetch(key, &block)
    if has_key?(key) 
      self[key] 
    elsif block
      self[key] = block.call
    else
      nil
    end
  end
end
