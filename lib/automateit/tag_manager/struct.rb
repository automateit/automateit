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
    @struct = _resolve_groups_and_negations(opts[:struct]) if opts[:struct]

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

  def _resolve_groups_and_negations(struct)
    # TODO TagManager::Struct#_resolve_groups_and_negations - write a less awful algorithm.
    def restruct(input)
      def trace(msg); puts msg if false; end # Prints low-level debugging info
      output = {}
      trace "in %s" % input.inspect
      for tag, hosts in input
        trace "tag %s" % tag
        for host in hosts
          trace " host %s" % host
          output[tag] ||= []
          if host.is_a?(::YAML::DomainType) and host.value.empty?
            # Negations get parsed as symbols in YAML, replace them
            output[tag].delete(host.type_id)
            output[tag] << "^%s"%host.type_id
            trace "  replaced YAML host %s" % host.type_id
          elsif host.match(/[!\^]@(\w+)/)
            # Group subtract with !@group
            output[tag].delete("@%s"%$1)
            output[tag] -= input[$1]
            trace "  negated group %s" % $1
          elsif host.match(/@(\w+)/)
            # Group add with @group
            output[tag] += input[$1]
            trace "  added group %s" % $1
          elsif host.match(/[!\^](\w+)/)
            # Host negation with !host
            output[tag].delete($1)
            trace "  negated struct host %s" % $1
          else
            output[tag] << host
          end
        end
      end
      trace "out %s" % output.inspect
      return output
    end

    while not struct.values.flatten.grep(/[@\!\^]/).empty?
      before = struct
      struct = restruct(struct)
      #puts "%s became %s" % [before.inspect, struct.inspect]; sleep 1
    end
    return struct
  end
  private :_resolve_groups_and_negations

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
