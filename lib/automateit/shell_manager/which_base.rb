# == ShellManager::WhichBase
#
# Provides abstract helper methods for other drivers implementing the +which+.
class AutomateIt::ShellManager::WhichBase < AutomateIt::ShellManager::BaseDriver
  abstract_driver

  def suitability(method, *args) # :nodoc:
    # Level must be higher than Portable
    return available? ? 2 : 0
  end

  # See ShellManager#which!
  def which!(command)
    result = which(command)
    if result.nil?
      raise ArgumentError.new("command not found: #{command}")
    else
      true
    end
  end

protected

  def _which_helper(&block)
    data = block.call
    data.strip! if data
    return (! data.blank? && File.exists?(data)) ? data : nil
  end

end
