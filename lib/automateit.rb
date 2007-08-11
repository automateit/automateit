#--
# TODO include selections from the "b" branch of interpreter
# TODO rename stuff to match new naming conventions

# TODO add logic to guess project path
# TODO add Environment

require 'rubygems'
require 'active_support'
require 'set'
require 'logger'

# Core
require 'automateit/common'
require 'automateit/interpreter'
require 'automateit/plugin'

# Helpers
require 'automateit/cli'

# Plugins
require 'automateit/address_manager'
require 'automateit/field_manager'
require 'automateit/platform_manager'
require 'automateit/shell_manager'
require 'automateit/tag_manager'
