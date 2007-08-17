require 'automateit'

module AutomateIt
  class TagManager < Plugin::Manager
    alias_methods :hosts_tagged_with, :hostname_aliases_for, :tags, :tags=, :tagged?, :tags_for

    def hosts_tagged_with(query) dispatch(query) end

    def tags() dispatch() end

    def tags=() dispatch() end

    def tagged?(query, hostname=nil) dispatch(query, hostname) end

    def tags_for(hostname) dispatch(hostname) end

    def hostname_aliases() dispatch() end

    def hostname_aliases=(aliases) dispatch(aliases) end

    def hostname_aliases_for(hostname) dispatch(hostname) end

    class Struct < Plugin::Driver
      attr_accessor :hostname_aliases, :tags

      def suitability(method, *args)
        return 1
      end

      def setup(opts={})
        super(opts)

        if opts[:hostname_aliases]
          @hostname_aliases = Set.new(opts[:hostname_aliases])
        else
          @hostname_aliases ||= Set.new
        end

        @tags ||= Set.new
        hostnames = [@hostname_aliases.to_a \
          + interpreter.address_manager.hostnames.to_a].flatten.uniq
        @tags.merge(hostnames)

        if opts[:struct]
          # TODO parse @group and !negation
          @struct = opts[:struct]
          @tags.merge(tags_for(hostnames))
        else
          @struct ||= {}
        end

        @tags.add(interpreter.platform_manager.query("os")) rescue IndexError
        @tags.add(interpreter.platform_manager.query("arch")) rescue IndexError
        @tags.add(interpreter.platform_manager.query("distro")) rescue IndexError
        @tags.add(interpreter.platform_manager.query("release")) rescue IndexError
        @tags.add(interpreter.platform_manager.query("os#arch")) rescue IndexError
        @tags.add(interpreter.platform_manager.query("distro#release")) rescue IndexError
      end

      def hosts_tagged_with(query)
        hosts = @struct.values.flatten.uniq
        return hosts.select{|hostname| tagged?(query, hostname)}
      end

      def tagged?(query, hostname=nil)
        query = query.to_s
        tags = hostname ? tags_for(hostname) : @tags
        # XXX This tokenization process discards unknown characters, which may hide errors in the query
        tokens = query.scan(%r{\(|\)|\&+|\|+|!?[\.\w]+})
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

      def tags_for(hostname)
        hostnames = String === hostname ? hostname_aliases_for(hostname) : hostname.to_a
        return @struct.inject(Set.new) do |sum, value|
          role, members = value
          members_aliases = members.inject(Set.new) do |aliases, member|
            aliases.merge(hostname_aliases_for(member)); aliases
          end.to_a
          sum.add(role) unless (hostnames & members_aliases).empty?
          sum
        end
      end

      def hostname_aliases_for(hostname)
        # Progressively strip a hostname of its domain elements
        tokens = hostname.split(/\./)
        return (1..tokens.size).inject([]) do |aliases, i|
          aliases << tokens[0,i].join('.');aliases
        end
      end

    end

    require 'erb'
    require 'yaml'
    class YAML < Struct
      def suitability(method, *args)
        return 5
      end

      def setup(opts={})
        if filename = opts.delete(:file)
          opts[:struct] = ::YAML::load(ERB.new(_read(filename), nil, '-').result)
        end
        super(opts)
      end

      def _read(filename)
        return File.read(filename)
      end
      private :_read

    end
  end
end
