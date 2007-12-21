# == PackageManager::DPKG
#
# The DPKG driver for the PackageManager provides a way to manage software
# packages on Debian-style systems using <tt>dpkg</tt>.
class AutomateIt::PackageManager::DPKG < AutomateIt::PackageManager::BaseDriver
  depends_on :programs => %w(dpkg)

  def suitability(method, *args) # :nodoc:
    return available? ? 1 : 0
  end

  # See AutomateIt::PackageManager#installed?
  def installed?(*packages)
    return _installed_helper?(*packages) do |list, opts|
      ### data = `dpkg --status nomarch apache2 not_a_real_package 2>&1`
      cmd = "dpkg --status "+list.join(" ")+" 2>&1"

      log.debug(PEXEC+cmd)
      data = `#{cmd}`
      matches = data.scan(/^Package: (.+)$\s*^Status: (.+)$/)
      available = matches.inject([]) do |sum, match|
        package, status = match
        sum << package if status.match(/(?:^|\s)installed\b/)
        sum
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
      cmd = "export DEBIAN_FRONTEND=noninteractive; dpkg --install --skip-same-version "+list.join(" ")+" < /dev/null"
      cmd << " > /dev/null" if opts[:quiet]
      cmd << " 2>&1"

      interpreter.sh(cmd)
    end
  end

  # See AutomateIt::PackageManager#uninstall
  def uninstall(*packages)
    return _uninstall_helper(*packages) do |list, opts|
      cmd = "export DEBIAN_FRONTEND=noninteractive; dpkg --remove "+list.join(" ")+" < /dev/null"
      cmd << " > /dev/null" if opts[:quiet]
      cmd << " 2>&1"

      interpreter.sh(cmd)
    end
  end
end

