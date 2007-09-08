# == PlatformManager
#
# The PlatformManager provides a way to query platform identifiers, such as
# the operating system distribution's version.
class AutomateIt::PlatformManager < AutomateIt::Plugin::Manager
  # Query the +search+ field. The +search+ can either be a key or a set of
  # keys separated by "#" signs.
  #
  # Examples:
  #   query(:os) # => "linux"
  #   query("arch") # => "i686"
  #   query("os#arch") # => "linux_i686"
  #   query("os#arch#distro#release") # => "linux_i686_ubuntu_6.06"
  #
  # Fields that may be provided by drivers:
  # * :arch -- Hardware architecture, e.g., "i686"
  # * :os -- Operating system, e.g., "linux"
  # * :distro -- Operating system distribution, e.g., "ubuntu"
  # * :release -- Operating system distribution release, e.g., "6.06"
  def query(search) dispatch(search) end

  # Is this a single-vendor operating system? E.g., Windows is, while Linux
  # isn't. This method helps the TagManager determine how to name tags. A
  # single-vendor product uses the "os#release" format (e.g., "windows_xp"),
  # while a multi-vendor product uses a "distro#release" format
  # ("ubuntu_6.06").
  def single_vendor?() dispatch() end
end

# == PlatformManager::AbstractDriver
#
# Base class for all PlatformManager drivers.
class AutomateIt::PlatformManager::AbstractDriver < AutomateIt::Plugin::Driver
  abstract_plugin
end

# Drivers
require 'automateit/platform_manager/struct'
require 'automateit/platform_manager/uname'
require 'automateit/platform_manager/lsb'
require 'automateit/platform_manager/debian'
require 'automateit/platform_manager/gentoo'
require 'automateit/platform_manager/windows'
