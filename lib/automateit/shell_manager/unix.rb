module AutomateIt
  class ShellManager
    # == ShellManager::UNIX
    #
    # A ShellManager driver for proving shell commands on UNIX-like systems.
    # Subclasses the Portable driver and provides some additional
    # functionality.
    class UNIX < Portable
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
          raise NotImplementedError.new("command not found: #{command}")
        end
      end
    end
  end
end
