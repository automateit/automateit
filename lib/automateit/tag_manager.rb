# == TagManager
#
# The TagManager provides a way of querying tags. Tags are keywords
# associated with a specific hostname or group. These are useful for grouping
# together hosts and defining common behavior for them.
#
# === Basics
#
# The tags are typically stored in a Project's <tt>config/tags.yml</tt> file.
#
# For example, consider this <tt>config/tags.yml</tt> file:
#   desktops:
#     - satori
#     - sunyata
#     - michiru
#   notebooks:
#     - rheya
#     - avijja
#
# With the above file, if we're on the host called "satori", we can query the
# fields like this:
#   tags # => ["satori", "desktops", "localhost", ...]
#
#   tagged?("desktops") # => true
#   tagged?("notebooks") # => false
#   tagged?(:satori) # => true
#   tagged?("satori") # => true
#   tagged?("satori || desktops") # => true
#   tagged?("(satori || desktops) && !notebooks") # => true
#
# === Traits
#
# Your system may also automatically add tags that describe your system's
# traits, such as the name of the operating system, distribution release,
# hardware architecture, hostnames, IP addresses, etc.
#
# For example, here is a full set of tags for a system:
#
#  ai> pp tags.sort                # Pretty print the tags in sorted order
#  ["10.0.0.6",                    # IPv4 addresses
#   "127.0.0.1",                   # ...
#   "192.168.130.1",               # ...
#   "::1/128",                     # IPv6 addresses
#   "fe80::250:56ff:fec0:8/64",    # ...
#   "fe80::250:8dff:fe95:8fe9/64", # ...
#   "i686",                        # Hardware architecture
#   "linux",                       # OS
#   "linux_i686",                  # OS and architecture
#   "localhost",                   # Variants of hostname
#   "localhost.localdomain",       # ...
#   "michiru",                     # ...
#   "michiru.koshevoy",            # ...
#   "michiru.koshevoy.net",        # ...
#   "myapp_servers",               # User defined tags
#   "rails_servers",               # ...
#   "ubuntu",                      # OS distribution name
#   "ubuntu_6.06"]                 # OS distribution name and release version
#
# To execute code only on an Ubuntu system:
#
#   if tagged?("ubuntu")
#     # Code will only be run on Ubuntu systems
#   end
#
# These additional tags are retrieved from the PlatformManager and
# AddressManager. If your platform does not provide drivers for these, you will
# not get these tags. If you're on an unsupported platform and do not want to
# write drivers, you can work around this by manually declaring the missing
# tags in <tt>config/tags.yml</tt> on a host-by-host basis.
#
# === Inclusion and negation
#
# You can include and negate tags declaratively by giving "@" and "!" prefixes
# to arguments.
#
# For example, consider this <tt>config/tags.yml</tt> file:
#
#   apache_servers:
#     - kurou
#     - shirou
#   apache_servers_except_kurou:
#     - @apache_servers
#     - !kurou
#
# This will produce the following results:
#
#   ai> hosts_tagged_with("apache_servers")
#   => ["kurou", "shirou"]
#   ai> hosts_tagged_with("apache_servers_except_kurou")
#   => ["shirou"]
class AutomateIt::TagManager < AutomateIt::Plugin::Manager
  alias_methods :hosts_tagged_with, :tags, :tagged?, :tags_for

  # Return a list of hosts that match the query. See #tagged? for information
  # on query syntax.
  def hosts_tagged_with(query) dispatch(query) end

  # Return a list of tags for this host.
  def tags() dispatch() end

  # Is this host tagged with the +query+?
  #
  # Examples:
  #   tags # => ["localhost", "foo", "bar", ...]
  #
  #   tagged?(:localhost) # => true
  #   tagged?("localhost") # => true
  #   tagged?("localhost && foo") # => true
  #   tagged?("localhost || foo") # => true
  #   tagged?("!foo") # => false
  #   tagged?("(localhost || foo) && bar") # => true
  def tagged?(query, hostname=nil) dispatch(query, hostname) end

  # Return a list of tags for the host.
  def tags_for(hostname) dispatch(hostname) end
end

# == TagManager::BaseDriver
#
# Base class for all TagManager drivers.
class AutomateIt::TagManager::BaseDriver < AutomateIt::Plugin::Driver
end

# Drivers
require 'automateit/tag_manager/tag_parser'
require 'automateit/tag_manager/struct'
require 'automateit/tag_manager/yaml'
