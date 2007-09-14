# == TagManager::Struct
#
# A TagManager driver for querying a data structure. It's not useful on its
# own, but can be subclassed by other drivers that actually load tags.
class AutomateIt::TagManager::Struct < AutomateIt::TagManager::BaseDriver
  depends_on :nothing

  attr_accessor :tags

  def suitability(method, *args) # :nodoc:
    return 1
  end

  # Options:
  # * :struct -- Hash to use for queries.
  def setup(opts={})
    # XXX Consider refactoring tags using lazy-loading.
    super(opts)

    @struct ||= {}
    if opts[:struct]
      @struct = AutomateIt::TagManager::TagParser.new(opts[:struct]).expand
    end

    @tags ||= Set.new

    hostnames = interpreter.address_manager.hostnames.to_a # SLOW 0.4s
    @tags.merge(hostnames)
    @tags.merge(tags_for(hostnames))

    begin
      @tags.add(interpreter.platform_manager.query("os")) rescue IndexError
      @tags.add(interpreter.platform_manager.query("arch")) rescue IndexError
      @tags.add(interpreter.platform_manager.query("distro")) rescue IndexError
      @tags.add(interpreter.platform_manager.query("release")) rescue IndexError
      @tags.add(interpreter.platform_manager.query("os#arch")) rescue IndexError
      if interpreter.platform_manager.single_vendor?
        # E.g. windows_xp
        @tags.add(interpreter.platform_manager.query("os#release")) rescue IndexError
      else
        # E.g. ubuntu_6.06
        @tags.add(interpreter.platform_manager.query("distro#release")) rescue IndexError
      end
    rescue NotImplementedError => e
      log.debug("this platform doesn't have a PlatformManager driver: #{e}")
    end
  end

  # See TagManager#hosts_tagged_with
  def hosts_tagged_with(query)
    hosts = @struct.values.flatten.uniq
    return hosts.select{|hostname| tagged?(query, hostname)}
  end

  # See TagManager#tagged?
  def tagged?(query, hostname=nil)
    query = query.to_s
    tags = hostname ? tags_for(hostname) : @tags
    # XXX This tokenization process discards unknown characters, which may hide errors in the query
    tokens = query.scan(%r{\!|\(|\)|\&+|\|+|!?[\.\w]+})
    if tokens.size > 1
      booleans = tokens.map do |token|
        if matches = token.match(/^(!?)([\.\w]+)$/)
          tags.include?(matches[2]) && matches[1].empty?
        else
          token
        end
      end
      code = booleans.join(" ")
      return eval(code) # XXX What could possibly go wrong?
    else
      return tags.include?(query)
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
