# == TagManager::Struct
#
# A TagManager driver for querying a data structure. It's not useful on its
# own, but can be subclassed by other drivers that actually load tags.
class AutomateIt::TagManager::Struct < AutomateIt::TagManager::BaseDriver
  depends_on :nothing

  def suitability(method, *args) # :nodoc:
    return 1
  end

  # Options:
  # * :struct -- Hash to use for queries.
  def setup(opts={})
    super(opts)

    if opts[:struct]
      @struct = AutomateIt::TagManager::TagParser.expand(opts[:struct])
      @tags   = Set.new
    else
      @struct ||= {}
      @tags   ||= Set.new
    end
  end

  # Return tags, populate them if necessary.
  def tags
    if @tags.empty?
      begin
        hostnames = interpreter.address_manager.hostnames # SLOW 0.4s
        @tags.merge(hostnames)
        @tags.merge(tags_for(hostnames))
        @tags.merge(interpreter.address_manager.addresses)
      rescue NotImplementedError => e
        log.debug("Can't find AddressManager for this platform: #{e}")
      end

      begin
        @tags.merge(interpreter.platform_manager.tags)
      rescue NotImplementedError => e
        log.debug("Can't find PlatformManager for this platform: #{e}")
      end
    end
    @tags
  end

  # See TagManager#hosts_tagged_with
  def hosts_tagged_with(query)
    hosts = @struct.values.flatten.uniq
    return hosts.select{|hostname| tagged?(query, hostname)}
  end

  # See TagManager#tagged?
  def tagged?(query, hostname=nil)
    query = query.to_s
    selected_tags = hostname ? tags_for(hostname) : tags
    # XXX This tokenization process discards unknown characters, which may hide errors in the query
    tokens = query.scan(%r{\!|\(|\)|\&+|\|+|!?[\.\w]+})
    if tokens.size > 1
      booleans = tokens.map do |token|
        if matches = token.match(/^(!?)([\.\w]+)$/)
          selected_tags.include?(matches[2]) && matches[1].empty?
        else
          token
        end
      end
      code = booleans.join(" ")

      begin
        return eval(code) # XXX What could possibly go wrong?
      rescue Exception => e
        raise ArgumentError.new("Invalid query -- #{query}")
      end
    else
      return selected_tags.include?(query)
    end
  end

  # See TagManager#tags_for
  def tags_for(hostnames)
    hostnames = \
      case hostnames
      when String
        interpreter.address_manager.hostnames_for(hostnames)
      when Array, Set
        hostnames.inject(Set.new) do |sum, hostname|
          sum.merge(interpreter.address_manager.hostnames_for(hostname)); sum
        end
      else
        raise TypeError.new("invalid hostnames argument type: #{hostnames.class}")
      end
    return @struct.inject(Set.new) do |sum, role_and_members|
      role, members = role_and_members
      members_aliases = members.inject(Set.new) do |aliases, member|
        aliases.merge(interpreter.address_manager.hostnames_for(member)); aliases
      end.to_a
      sum.add(role) unless (hostnames & members_aliases).empty?
      sum
    end
  end
end
