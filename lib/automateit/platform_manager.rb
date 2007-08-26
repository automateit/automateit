require 'automateit'

module AutomateIt
  # == PlatformManager
  #
  # The PlatformManager provides a way to query platform identifiers, such as
  # the operating system distribution's version.
  class PlatformManager < Plugin::Manager
    require 'automateit/platform_manager/struct'
    require 'automateit/platform_manager/uname'
    require 'automateit/platform_manager/lsb'

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
    # * :arch -- Hardware architecture, e.g. "i686"
    # * :os -- Operating system, e.g. "linux"
    # * :distro -- Operating system distribution, e.g. "ubuntu"
    # * :release -- Operating system distribution release, e.g. "6.06"
    def query(search) dispatch(search) end
  end
end
