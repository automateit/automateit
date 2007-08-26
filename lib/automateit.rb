# == Dependencies
#
# Require AutomateIt's dependencies.

# Standard libraries
require 'expect'
require 'fileutils'
require 'logger'
require 'open3'
require 'pty'
require 'set'
require 'yaml'
require 'find'
require 'etc'
require 'resolv'
require 'socket'

# Gems
require 'rubygems'
require 'active_support' # SLOW 0.5s
require 'open4'
begin
  require 'eruby'
rescue LoadError
  require 'erb'
end

# Patches
require 'patches/object.rb'
require 'patches/metaclass.rb'

# Core
require 'automateit/root'
require 'automateit/common'
require 'automateit/interpreter'
require 'automateit/plugin'
require 'automateit/cli'
require 'automateit/project'

# Helpers
require 'hashcache'
require 'queued_logger'
require 'tempster'

# Plugins which must be loaded early
require 'automateit/shell_manager'
require 'automateit/platform_manager' # requires shell
require 'automateit/address_manager' # requires shell
require 'automateit/tag_manager' # requires address, platform
require 'automateit/field_manager' # requires shell
require 'automateit/service_manager' # requires shell
require 'automateit/package_manager' # requires shell
require 'automateit/template_manager'
require 'automateit/edit_manager'
require 'automateit/account_manager'
