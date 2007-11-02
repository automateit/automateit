# == PackageManager::PECL
#
# A PackageManager driver for PECL (PHP Extension Community Library), manages
# software packages using the <tt>pecl</tt> command.
class ::AutomateIt::PackageManager::PECL < ::AutomateIt::PackageManager::BaseDriver
  depends_on :programs => %w(pecl)

  def suitability(method, *args) # :nodoc:
    # Never select as default driver
    return 0
  end

  # Retrieve a hash containing all installed packages, indexed by package
  # name.  Each value is a hash containing values for :channel, :version,
  # and :state.
  def get_installed_packages()
    cmd = "pecl list -a 2>&1"
    data = `#{cmd}`
    installed_packages = {}
    data.scan(/^([^(\s]+)\s+([^\s]+)\s+([^\s]+)$/) do |package, version, state|
      next if version.upcase == 'VERSION'
      installed_packages[package] = {:version => version, :state => state}
    end
    return installed_packages
  end
  protected :get_installed_packages

  # See AutomateIt::PackageManager#installed?
  def installed?(*packages)
    return _installed_helper?(*packages) do |list, opts|
      all_installed = get_installed_packages().keys.collect {|pkg| pkg.downcase}

      result = []
      list.each do |pkg|
        pkg_without_channel = pkg.gsub(%r{^[^/]+/}, '').downcase
        result.push pkg if all_installed.include?(pkg_without_channel)
      end

      result
    end
  end


  # See AutomateIt::PackageManager#not_installed?
  def not_installed?(*packages)
    return _not_installed_helper?(*packages)
  end

  # Options:
  # * :force -- Force installation, needed when installing unstable packages
  #
  # See AutomateIt::PackageManager#install
  def install(*packages)
    return _install_helper(*packages) do |list, opts|
      # pecl options:
      # -a install all required dependencies
      # -f force installation

      cmd = "pecl install -a"
      cmd << " -f" if opts[:force]
      cmd << " "+list.join(" ")+" < /dev/null"
      cmd << " > /dev/null" if opts[:quiet]
      cmd << " 2>&1"

      interpreter.sh(cmd)
    end
  end

  # See AutomateIt::PackageManager#uninstall
  def uninstall(*packages)
    return _uninstall_helper(*packages) do |list, opts|

      cmd = "pecl uninstall "+list.join(" ")+" < /dev/null"
      cmd << " > /dev/null" if opts[:quiet]
      cmd << " 2>&1"

      interpreter.sh(cmd)
    end
  end
end
