# == ShellManager::Link
#
# A ShellManager driver providing access to the hard link +ln+ command found on
# Unix-like systems.
class AutomateIt::ShellManager::Link < AutomateIt::ShellManager::BaseLink
  depends_on :callbacks => [lambda{
      File.respond_to?(:link)
    }]

  def suitability(method, *args) # :nodoc:
    # Level must be higher than Portable
    return available? ? 2 : 0
  end

  # See ShellManager#provides_link?
  def provides_link?
    available? ? true : false
  end

  # See ShellManager#ln
  def ln(*args)
    _ln(*args)
  end
end
