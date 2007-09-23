# == ShellManager::Symlink
#
# A ShellManager driver providing access to the symbolic link +ln_s+ command
# found on Unix-like systems.
class AutomateIt::ShellManager::Symlink < AutomateIt::ShellManager::BaseLink
  depends_on \
    :libraries => %w(pathname),
    :callbacks => [lambda{
      # TODO ShellManager::Symlink - Dynamically detect if platform really can read symlinks. The problem with JRuby is that it accepts all the symlink commands -- but it just can't read them, which effectively breaks all of AutomateIt's conditional logic..
      File.respond_to?(:symlink) \
        && RUBY_PLATFORM !~ /java/i
    }]

  def suitability(method, *args) # :nodoc:
    # Level must be higher than Portable
    return available? ? 2 : 0
  end

  # See ShellManager#provides_symlink?
  def provides_symlink?
    available? ? true : false
  end

  # See ShellManager#ln_s
  def ln_s(sources, target, opts={})
    _ln(sources, target, {:symbolic => true}.merge(opts))
  end

  # See ShellManager#ln_sf
  def ln_sf(sources, target, opts={})
    _ln(sources, target, {:symbolic => true, :force => true}.merge(opts))
  end
end
