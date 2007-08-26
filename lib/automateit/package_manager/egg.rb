module AutomateIt
  class PackageManager
    # == PackageManager::Egg
    #
    # The Egg driver for the PackageManager provides a way to manage
    # Python software packages with the PEAK +easy_install+ tool.
    class Egg < Plugin::Driver
      include PackageManagerHelpers

      depends_on :programs => %w(python easy_install)

      def suitability(method, *args) # :nodoc:
        # Never select as default driver
        return 0
      end

      # See AutomateIt::PackageManager#installed?
      def installed?(*packages)
        return _installed_helper?(*packages) do |list, opts|
          cmd = "python -c 'import sys; print(sys.path)' 2>&1"

          log.debug(PEXEC+cmd)
          data = `#{cmd}`
          # Extract array elements, turn them into basenames, and then split on
          # '-' because that's the separator for the name and version.
          found = data.scan(/'([^']+\.egg)'/).flatten.map{|t| File.basename(t).split('-', 2)[0]}
          available = found & list
        end
      end

      # See AutomateIt::PackageManager#not_installed?
      def not_installed?(*packages)
        return _not_installed_helper?(*packages)
      end

      # See AutomateIt::PackageManager#install
      def install(*packages)
        return _install_helper(*packages) do |list, opts|
          # easy_install options:
          # -Z : install into a direcory rather than a file
          cmd = "easy_install -Z "+list.join(" ")+" < /dev/null"
          cmd << " > /dev/null" if opts[:quiet]
          cmd << " 2>&1"

          interpreter.sh(cmd)
        end
      end

      # See AutomateIt::PackageManager#uninstall
      def uninstall(*packages)
        return _uninstall_helper(*packages) do |list, opts|
          # easy_install options:
          # -m : removes package from the easy-install.pth
          cmd = "easy_install -m "+list.join(" ")+" < /dev/null"
          cmd << " > /dev/null" if opts[:quiet]
          cmd << " 2>&1"

          # Parse output for paths and remove the orphaned entries
          log.info(PEXEC+cmd)
          return packages if noop?
          data = `#{cmd}`
          paths = data.scan(/^Using ([^\n]+\.egg)$/m).flatten
          for path in paths
            interpreter.rm_rf(path)
          end
        end
      end
    end
  end
end
