# == PackageManager::CPAN
#
# A PackageManager driver for Perl CPAN (Comprehensive Perl Archive Network)
# software packages.
class ::AutomateIt::PackageManager::CPAN < ::AutomateIt::PackageManager::BaseDriver
  CPAN_INSTALL = File.join(::AutomateIt::Constants::HELPERS_DIR, "cpan_install.pl")
  CPAN_UNINSTALL = File.join(::AutomateIt::Constants::HELPERS_DIR, "cpan_uninstall.pl")
  CPAN_IS_INSTALLED = File.join(::AutomateIt::Constants::HELPERS_DIR, "cpan_is_installed.pl")

  depends_on :programs => %w(perl)

  def suitability(method, *args) # :nodoc:
    # Never select as default driver
    return 0
  end

  # See AutomateIt::PackageManager#installed?
  def installed?(*packages)
    return _installed_helper?(*packages) do |list, opts|
      cmd = "#{CPAN_IS_INSTALLED} #{list.join(' ')}"

      log.debug(PEXEC+cmd)
      output = `#{cmd}`
      output.sub!(/.*---(\s[^\n]+)?\n/m, '')
      struct = ::YAML.load(output)

      struct["available"] || []
    end
  end

  # See AutomateIt::PackageManager#not_installed?
  def not_installed?(*packages)
    return _not_installed_helper?(*packages)
  end

  # *IMPORTANT*: See documentation at the top of this file for how to correctly
  # install packages from a specific channel.
  #
  # Options:
  # * :force -- Force installation, needed when installing unstable packages
  #
  # See AutomateIt::PackageManager#install
  def install(*packages)
    return _install_helper(*packages) do |list, opts|
      cmd = "#{CPAN_INSTALL} #{list.join(' ')}"
      cmd << " > /dev/null" if opts[:quiet]
      cmd << " 2>&1"

      interpreter.sh(cmd)
    end
  end

  # See AutomateIt::PackageManager#uninstall
  def uninstall(*packages)
    return _uninstall_helper(*packages) do |list, opts|
      cmd = "#{CPAN_UNINSTALL} #{list.join(' ')} < /dev/null"
      cmd << " > /dev/null" if opts[:quiet]
      cmd << " 2>&1"

      interpreter.sh(cmd)
    end
  end
end
