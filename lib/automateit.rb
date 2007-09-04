# == Dependencies

# Standard libraries
require 'etc'
require 'fileutils'
require 'find'
require 'logger'
require 'open3'
require 'pp'
require 'pathname'
require 'resolv'
require 'set'
require 'socket'
require 'yaml'

# Gems
require 'rubygems'
require 'open4'
require 'erb'

# Load ActiveSupport pieces individually to save ~0.5s
### require 'active_support'
require 'active_support/core_ext/blank'
require 'active_support/core_ext/class/attribute_accessors'
require 'active_support/core_ext/class/inheritable_attributes'
require 'active_support/core_ext/module/aliasing'
require 'active_support/core_ext/string'
require 'active_support/clean_logger'

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
