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
require 'erb'

# ActiveSupport-like features
require 'inactive_support'

# Extensions
require 'ext/object.rb'
require 'ext/metaclass.rb'
require 'ext/shell_escape.rb'

# Helpers
require 'hashcache'
require 'queued_logger'
require 'tempster'
require 'helpful_erb'
require 'nested_error'
require 'nitpick'

# Core
require 'automateit/root'
require 'automateit/constants'
require 'automateit/error'
require 'automateit/common'
require 'automateit/interpreter'
require 'automateit/plugin'
require 'automateit/cli'
require 'automateit/project'

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
require 'automateit/download_manager'
