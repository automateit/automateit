# == PackageManager::APT
#
# The APT driver for the PackageManager provides a way to manage software
# packages on Debian-style systems using <tt>apt-get</tt> and <tt>dpkg</tt>.
class AutomateIt::PackageManager::APT < AutomateIt::PackageManager::DPKG
  depends_on :programs => %w(apt-get dpkg)

  def suitability(method, *args) # :nodoc:
    return available? ? 1 : 0
  end

  # See AutomateIt::PackageManager#install
  def install(*packages)
    return _install_helper(*packages) do |list, opts|
      # apt-get options:
      # -y : yes to all queries
      # -q : no interactive progress bars
      cmd = "export DEBIAN_FRONTEND=noninteractive; apt-get install -y -q "+list.join(" ")+" < /dev/null"
      cmd << " > /dev/null" if opts[:quiet]
      cmd << " 2>&1"

      interpreter.sh(cmd)
    end
  end
end
