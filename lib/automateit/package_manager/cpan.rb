# == PackageManager::CPAN
#
# A PackageManager driver for Perl CPAN (Comprehensive Perl Archive Network)
# software packages.
#
# === No automatic dependency installation
#
# Unlike other AutomateIt PackageManager drivers, the CPAN driver will not install a package's dependencies automatically. This protects you because many CPAN packages require a specific version of Perl, often one which you don't have installed, and installing that dependency will destroy your Perl interpreter and everything that depends on it. Therefore, you must specify all package dependencies manually. If a package dependency isn't found, the install will fail.
#
# === Specifying Perl interpreter
#
# Use #setup to specify the Perl interpreter to use for all subsequent calls.
#
# Example:
#
#   package_manager[:cpan].setup(:perl => "/usr/local/bin/perl")
#   package_manager.install %w(File::Next App::Ack), :with => :cpan
class ::AutomateIt::PackageManager::CPAN < ::AutomateIt::PackageManager::BaseDriver
  CPAN_INSTALL = File.join(::AutomateIt::Constants::HELPERS_DIR, "cpan_install.pl")
  CPAN_UNINSTALL = File.join(::AutomateIt::Constants::HELPERS_DIR, "cpan_uninstall.pl")
  CPAN_IS_INSTALLED = File.join(::AutomateIt::Constants::HELPERS_DIR, "cpan_is_installed.pl")

  # Path to Perl interpreter
  attr_accessor :perl

  # FIXME How to get #depends_on to use same Perl interpreter as #perl? The trouble is that Plugin::Driver#available? checks a class variable populated by #depends_on, so it can't see the instance's #perl variable that's been set by the user. A general solution would address this problem for all drivers that use commands with different names, e.g. "gem1.8", "python2.5.1", etc.
  depends_on :programs => %w(perl)

  # Setup the PackageManager::CPAN driver.
  #
  # Options:
  # * :perl -- The absolute, relative or unqualified path for the Perl interpreter to use. E.g., "perl" or "/usr/local/bin/perl".
  def setup(*args)
    super(*args)

    args, opts = args_and_opts(*args)
    if opts[:perl]
      self.perl = opts[:perl]
    else
      self.perl ||= "perl"
    end
  end

  def suitability(method, *args) # :nodoc:
    # Never select as default driver
    return 0
  end

  # Options:
  # * :perl -- Command to use as the Perl interpreter, otherwise defaults to the one specified during #setup or to "perl"
  #
  # See AutomateIt::PackageManager#installed?
  def installed?(*packages)
    return _installed_helper?(*packages) do |list, opts|
      perl = opts[:perl] || self.perl
      cmd = "#{perl} #{CPAN_IS_INSTALLED} #{list.join(' ')}"

      # FIXME if CPAN isn't configured, this will hang because Perl will demand input
      log.debug(PEXEC+cmd)
      output = `#{cmd}`
      output.sub!(/.*---(\s[^\n]+)?\n/m, '')
      struct = ::YAML.load(output)

      struct["available"] || []
    end
  end

  # See AutomateIt::PackageManager#not_installed?
  def not_installed?(*packages)
    # TODO Move #not_installed? up to BaseDriver
    return _not_installed_helper?(*packages)
  end

  # Options:
  # * :perl -- Command to use as the Perl interpreter, otherwise defaults to the one specified during #setup or to "perl"
  #
  # See AutomateIt::PackageManager#install
  def install(*packages)
    return _install_helper(*packages) do |list, opts|
      perl = opts[:perl] || self.perl
      cmd = "#{perl} #{CPAN_INSTALL} #{list.join(' ')}"
      cmd << " > /dev/null" if opts[:quiet]
      cmd << " 2>&1"

      interpreter.sh(cmd)
    end
  end

  # Options:
  # * :perl -- Command to use as the Perl interpreter, otherwise defaults to the one specified during #setup or to "perl"
  #
  # See AutomateIt::PackageManager#uninstall
  def uninstall(*packages)
    return _uninstall_helper(*packages) do |list, opts|
      perl = opts[:perl] || self.perl
      cmd = "#{perl} #{CPAN_UNINSTALL} #{list.join(' ')} < /dev/null"
      cmd << " > /dev/null" if opts[:quiet]
      cmd << " 2>&1"

      interpreter.sh(cmd)
    end
  end
end
