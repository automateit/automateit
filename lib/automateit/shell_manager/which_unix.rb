# == ShellManager::WhichUnix
#
# A ShellManager driver providing access to the +which+ command found on
# Unix-like systems.
class AutomateIt::ShellManager::WhichUnix < AutomateIt::ShellManager::WhichBase
  depends_on :programs => %w(which)

  # Inherits WhichBase#suitability

  # See ShellManager#which
  def which(command)
    _which_helper do
      `which #{command} 2>&1`
    end
  end
end
