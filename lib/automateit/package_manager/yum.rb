# == PackageManager::YUM
#
# The YUM driver for the PackageManager provides a way to manage software
# packages on Red Hat-style systems using +yum+ and +rpm+.
class AutomateIt::PackageManager::YUM < AutomateIt::PackageManager::BaseDriver
  depends_on :programs => %w(yum rpm)

  def suitability(method, *args) # :nodoc:
    return available? ? 1 : 0
  end

  # See AutomateIt::PackageManager#installed?
  def installed?(*packages)
    return _installed_helper?(*packages) do |list, opts|
      ### rpm -q --nosignature --nodigest --qf "%{NAME} # %{VERSION} # %{RELEASE}\n" httpd nomarch foo
      cmd = 'rpm -q --nosignature --nodigest --qf "%{NAME} # %{VERSION} # %{RELEASE}\n"'
      list.each{|package| cmd << " "+package}
      cmd << " 2>&1" # missing packages are listed on STDERR

      log.debug(PEXEC+cmd)
      data = `#{cmd}`
      matches = data.scan(/^(.+) # (.+) # .+$/)
      available = matches.inject([]) do |sum, match|
        package, status = match
        sum << package
        sum
      end
      available
    end
  end

  # See AutomateIt::PackageManager#not_installed?
  def not_installed?(*packages)
    _not_installed_helper?(*packages)
  end

  # See AutomateIt::PackageManager#install
  def install(*packages)
    return _install_helper(*packages) do |list, opts|
      # yum options:
      # -y : yes to queries
      # -d 0 : no debugging info
      # -e 0 : show only fatal errors
      # -C : don't download headers
      cmd = "yum -y -d 0 -e 0"
      cmd << " -C" if opts[:cache] == true
      cmd << " install "+list.join(" ")+" < /dev/null"
      cmd << " > /dev/null" if opts[:quiet]
      cmd << " 2>&1"

      interpreter.sh(cmd)
    end
  end

  # See AutomateIt::PackageManager#uninstall
  def uninstall(*packages)
    return _uninstall_helper(*packages) do |list, opts|
      cmd = "rpm --erase --quiet "+list.join(" ")+" < /dev/null"
      cmd << " > /dev/null" if opts[:quiet]
      cmd << " 2>&1"

      interpreter.sh(cmd)
    end
  end
end
