# == TagManager::TagParser
#
# Helper class for parsing tags. Not useful for users -- for internal use only.
class AutomateIt::TagManager::TagParser
  attr_accessor :struct
  attr_accessor :is_trace # FIXME replace is_trace with nitpick

  # Create a parser for the +struct+, a hash of tag keys to values with arrays of items.
  def initialize(struct, is_trace=false)
    self.struct = struct
    self.is_trace = is_trace
    normalize!
  end

  # Normalize a block of text to replace shortcut symbols that cause YAML to choke.
  def self.normalize(text)
    return text \
      .gsub(/^(\s*-\s+)(!@)/, '\1EXCLUDE_TAG ') \
      .gsub(/^(\s*-\s+)(!)/, '\1EXCLUDE_HOST ') \
      .gsub(/^(\s*-\s+)(@)/, '\1INCLUDE_TAG ')
  end

  # Normalize the contents of the internal struct.
  def normalize!
    for tag, items in struct
      next unless items
      for item in items
        next unless item
        item.gsub!(/^(\!@|\^@)\s*/, 'EXCLUDE_TAG ')
        item.gsub!(/^(\!|\^)\s*/, 'EXCLUDE_HOST ')
        item.gsub!(/^(@)\s*/, 'INCLUDE_TAG ')
      end
    end
  end

  # Display debugging information if +is_trace+ is enabled.
  def trace(msg)
    puts msg if is_trace
  end

  HOSTS_FOR_VALUE = /(.+?)/
  HOSTS_FOR_INCLUDE_TAG_RE = /^INCLUDE_TAG #{HOSTS_FOR_VALUE}$/
  HOSTS_FOR_EXCLUDE_TAG_RE = /^EXCLUDE_TAG #{HOSTS_FOR_VALUE}$/
  HOSTS_FOR_EXCLUDE_HOST_RE = /^EXCLUDE_HOST #{HOSTS_FOR_VALUE}$/

  # Return array of hosts for the +tag+.
  def hosts_for(tag)
    raise IndexError.new("Unknown tag - #{tag}") unless struct.has_key?(tag)
    return [] if struct[tag].nil? # Tag has no leaves

    trace "\nAA %s" % tag
    hosts = Set.new
    for item in struct[tag]
      case item
      when HOSTS_FOR_INCLUDE_TAG_RE
        trace "+g %s" % $1
        hosts.merge(hosts_for($1))
      when HOSTS_FOR_EXCLUDE_TAG_RE
        trace "-g %s" % $1
        hosts.subtract(hosts_for($1))
      when HOSTS_FOR_EXCLUDE_HOST_RE
        trace "-h %s" % $1
        hosts.delete($1)
      else
        trace "+h %s" % item
        hosts << item
      end
    end
    result = hosts.to_a
    trace "ZZ %s for %s" % [result.inspect, tag]
    return result
  end

  # Return array of tags.
  def tags
    return struct.keys
  end

  # Expand the include/exclude/group rules and return a struct with only the
  # hosts these rules produce.
  def expand
    result = {}
    for tag in tags
      result[tag] = hosts_for(tag)
    end
    result
  end

  # Replace the internal struct with an expanded version, see #expand.
  def expand!
    struct.replace(expand)
  end

  # Expand the +struct+.
  def self.expand(struct, is_trace=false)
    self.new(struct, is_trace).expand
  end
end
