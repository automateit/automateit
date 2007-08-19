# Standard libraries
require 'expect'
require 'fileutils'
require 'logger'
require 'open3'
require 'pty'
require 'set'
require 'yaml'

# Gems
require 'rubygems'
require 'active_support'
begin 
  require 'eruby'
rescue LoadError
  require 'erb'
end

# Patches
require 'patches/object.rb'

# Core
require 'automateit/common'
require 'automateit/interpreter'
require 'automateit/plugin'
require 'automateit/cli'
require 'hashcache'

# Plugins which must be loaded early
require 'automateit/shell_manager'
require 'automateit/platform_manager' # requires shell
require 'automateit/address_manager' # requires shell
require 'automateit/tag_manager' # requires address, platform
require 'automateit/field_manager' # requires shell
require 'automateit/service_manager' # requires shell
require 'automateit/package_manager' # requires shell
require 'automateit/template_manager'
