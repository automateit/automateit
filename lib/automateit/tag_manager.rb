require 'automateit'

module AutomateIt
  # == TagManager
  #
  # The TagManager provides a way of querying tags. Tags are keywords
  # associated with a specific hostname or group. These are useful for grouping
  # together hosts and defining common behavior for them. The tags are
  # typically stored in a project's <tt>config/tags.yml</tt> file.
  #
  # For example, consider a <tt>tags.yml</tt> file that contains YAML like:
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
  #   tagged?(:satori) # => true
  #   tagged?("satori") # => true
  #   tagged?("satori || sunyata") # => true
  #   tagged?("desktops") # => true
  #   tagged?("notebooks") # => false
  class TagManager < Plugin::Manager
    require 'automateit/tag_manager/struct'
    require 'automateit/tag_manager/yaml'

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
end
