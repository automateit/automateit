# == ShellManager::WhichWindows
#
# A ShellManager driver providing access to +which+ command by faking it on
# Windows systems.
class ::AutomateIt::ShellManager::WhichWindows < ::AutomateIt::ShellManager::WhichBase
  WHICH_HELPER = File.join(::AutomateIt::Constants::HELPERS_DIR, "which.cmd")

  # FIXME how to detect windows through Java?
  depends_on :callbacks => lambda { RUBY_PLATFORM =~ /mswin/i }

  # Inherits WhichBase#suitability

  # See ShellManager#which
  def which(command)
    _which_helper do
      data = `#{WHICH_HELPER} #{command} 2>&1`
    end
  end
end

