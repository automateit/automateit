# == ShellManager::Which
#
# A ShellManager driver providing access to the +which+ command found on
# Unix-like systems.
class AutomateIt::ShellManager::Which < AutomateIt::ShellManager::BaseDriver
  depends_on :programs => %w(which)

  def suitability(method, *args) # :nodoc:
    # Level must be higher than Portable
    return available? ? 2 : 0
  end

  # See ShellManager#which
  def which(command)
    data = `which "#{command}" 2>&1`.chomp
    return (! data.blank? && File.exists?(data)) ? data : nil
  end

  # See ShellManager#which!
  def which!(command)
    if which(command).nil?
      raise ArgumentError.new("command not found: #{command}")
    end
  end
end
