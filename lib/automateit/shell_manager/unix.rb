# == ShellManager::Unix
#
# A ShellManager driver for providing shell commands for manipulating files
# and executing commands on Unix-like systems.
#
# It includes all the functionality of the ShellManager::Portable driver
# plus additional commands.
class AutomateIt::ShellManager::Unix < AutomateIt::ShellManager::Portable
  depends_on :programs => %w(which)

  def suitability(method, *args) # :nodoc:
    # Level must be higher than Portable
    return available? ? 2 : 0
  end

  # See ShellManager#which
  def which(command)
    data = `which "#{command}" 2>&1`.chomp
    return File.exists?(data) ? data : nil
  end

  # See ShellManager#which!
  def which!(command)
    if which(command).nil?
      raise ArgumentError.new("command not found: #{command}")
    end
  end
end
