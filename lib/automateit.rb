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
require 'active_support/core_ext/blank' # foo.blank?
require 'active_support/core_ext/class/attribute_accessors' # cattr_accessor
require 'active_support/core_ext/class/inheritable_attributes' # inheritable_cattr_accessor
require 'active_support/core_ext/module/aliasing' # alias_method_chain
require 'active_support/core_ext/string' # "asdf".demodulize.underscore
require 'active_support/clean_logger' # cleans up Logger output
require 'active_support/core_ext/symbol' # [:foo, :bar].map(&:to_s)

# Handle ActiveSupport includes
require 'active_support/core_ext/hash/keys' # {:foo => :bar}.stringify_keys
Hash.module_eval{include ActiveSupport::CoreExtensions::Hash::Keys}

# Extensions
require 'ext/object.rb'
require 'ext/metaclass.rb'

# Helpers
require 'hashcache'
require 'queued_logger'
require 'tempster'
require 'helpful_erb'
require 'nested_error'

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
