# == InactiveSupport
#
# InactiveSupport is a subset of features copied from the Rails ActiveSupport
# 2.0.2 library, and retain the same ownership and licensing as the originals.
#
# Using this subset of ActiveSupport makes AutomateIt:
# * More reliable: InactiveSupport is guaranteed correctly to work because it's
#   part of AutomateIt. This is in contrast to ActiveSupport, which is
#   versioned separately and regularly introduces new bugs and breaks backwards
#   compatibility, which makes it unsuitable as a library.
# * Easier and faster install: Installing AutomateIt is easier and faster
#   because it no longer needs the ActiveSupport and Builder gems..
# * Quicker startup: InactiveSupport loads in a fraction of the time that
#   ActiveSupport takes.

require 'inactive_support/core_ext/array/extract_options' # [].extract_options
class Array
  include InactiveSupport::CoreExtensions::Array::ExtractOptions
end

require 'inactive_support/core_ext/blank' # foo.blank?
require 'inactive_support/core_ext/symbol' # [:foo, :bar].map(&:to_s)
require 'inactive_support/core_ext/module/aliasing' # alias_method_chain
require 'inactive_support/core_ext/class/attribute_accessors' # cattr_accessor
require 'inactive_support/core_ext/class/inheritable_attributes' # inheritable_cattr_accessor
require 'inactive_support/core_ext/enumerable' # sum

require 'inactive_support/core_ext/numeric/time' # 1.day
class Numeric
  include InactiveSupport::CoreExtensions::Numeric::Time
end

require 'inactive_support/core_ext/string/inflections' # "asdf".demodulize.underscore
class String
  include InactiveSupport::CoreExtensions::String::Inflections
end

require 'inactive_support/core_ext/hash/keys' # {:foo => :bar}.stringify_keys
class Hash
  include InactiveSupport::CoreExtensions::Hash::Keys
end

require 'inactive_support/basic_object' # Ruby 1.9 compatibility
require 'inactive_support/duration' # adds dates
require 'inactive_support/core_ext/time/conversions' # to_formatted_s
class Time
  include InactiveSupport::CoreExtensions::Time::Conversions
end

require 'inactive_support/clean_logger' # cleans up Logger output
