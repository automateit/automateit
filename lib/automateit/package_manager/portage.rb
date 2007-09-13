# == PackageManager::Portage
#
# The Portage driver for the PackageManager provides a way to manage software
# packages on Gentoo systems using.
class AutomateIt::PackageManager::Portage < AutomateIt::PackageManager::BaseDriver
  depends_on :programs => %w(emerge)

  def suitability(method, *args) # :nodoc:
    return available? ? 1 : 0
  end

  # See AutomateIt::PackageManager#installed?
  def installed?(*packages)
    return _installed_helper?(*packages) do |list, opts|
      # Emerge throws an error when called with invalid packages, so it's
      # necessary to find the invalid packages and re-run the command without
      # them to find out what is actually installed.
      missing = []
      available = []
      while true
        cmd = "emerge --color n --nospinner --tree --usepkg --quiet --pretend " + \
          (list-missing).join(' ') + " < /dev/null 2>&1"
        log.debug(PEXEC+cmd)
        output = `#{cmd}`

        if output.match(/no ebuilds to satisfy "(.+)"/)
          invalid = $1
          log.debug(PNOTE+"PackageManager::Portage.installed? skipping invalid package '#{invalid}'")
          missing << invalid
          break if (list-missing).size.zero?
        else
          matches = output.scan(%r{^\[\w+\s+R\s*\] .+/(\w+?)-.+$}).flatten
          available = list & matches
          break
        end
      end

      available
    end
  end

  # See AutomateIt::PackageManager#not_installed?
  def not_installed?(*packages)
    return _not_installed_helper?(*packages)
  end

  # See AutomateIt::PackageManager#install
  def install(*packages)
    return _install_helper(*packages) do |list, opts|
      cmd = "emerge --color n --nospinner --tree --usepkg --quiet #{list.join(' ')} < /dev/null"
      cmd << " > /dev/null" if opts[:quiet]
      cmd << " 2>&1"

      interpreter.sh(cmd)
    end
  end

  # See AutomateIt::PackageManager#uninstall
  def uninstall(*packages)
    return _uninstall_helper(*packages) do |list, opts|
      cmd = "emerge --color n --nospinner --tree --unmerge --quiet #{list.join(' ')} < /dev/null"
      cmd << " > /dev/null" if opts[:quiet]
      cmd << " 2>&1"

      interpreter.sh(cmd)
    end
  end
end

