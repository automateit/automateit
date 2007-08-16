#--
# TODO include selections from the "b" branch of interpreter
# TODO rename stuff to match new naming conventions

# TODO add logic to guess project path
# TODO add Environment

require 'rubygems'

# Dependencies
require 'active_support'
require 'fileutils'
require 'logger'
require 'open3'
require 'set'
require 'yaml'

# Core
require 'automateit/common'
require 'automateit/interpreter'
require 'automateit/plugin'

# Helpers
require 'automateit/cli'

# Plugins which must be loaded early
require 'automateit/shell_manager'
require 'automateit/platform_manager'
require 'automateit/tag_manager'

# Plugins which can be loaded later
require 'automateit/address_manager'
require 'automateit/field_manager'
require 'automateit/service_manager'
require 'automateit/template_manager'
require 'automateit/package_manager'
