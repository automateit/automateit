module AutomateIt
  # == PackageManager
  #
  # The PackageManager provides a way to manage packages, e.g., install,
  # uninstall and query if the Apache package is installed with APT.
  #
  # Examples:
  #   package_manager.installed?("apache2") # => false
  #   package_manager.install("apache2") # => true
  #   package_manager.installed?("apache2") # => true
  #   package_manager.uninstall("apache2") # => true
  #   package_manager.not_installed("apache2") # => true
  class PackageManager < Plugin::Manager
    require 'automateit/package_manager/helpers'
    require 'automateit/package_manager/apt'
    require 'automateit/package_manager/yum'
    require 'automateit/package_manager/gem'
    require 'automateit/package_manager/egg'

    # Are these +packages+ installed? Returns +true+ if all +packages+ are
    # installed, or an array of installed packages when called with an options
    # hash that contains <tt>:list => true</tt>
    def installed?(*packages) dispatch(*packages) end

    # Are these +packages+ not installed? Returns +true+ if none of these
    # +packages+ are installed, or a array of packages that aren't installed
    # when called with an options hash that contains <tt>:list => true</tt>
    def not_installed?(*packages) dispatch(*packages) end

    # Install these +packages+. Returns +true+ if install succeeded; or
    # +false+ if all packages were already installed.
    def install(*packages) dispatch(*packages) end

    # Uninstall these +packages+. Returns +true+ if uninstall succeeded; or
    # +false+ if none of the packages were installed.
    def uninstall(*packages) dispatch(*packages) end
  end
end
