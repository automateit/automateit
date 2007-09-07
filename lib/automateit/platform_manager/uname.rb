module AutomateIt
  class PlatformManager
    # == PlatformManager::Uname
    #
    # A PlatformManager driver that uses the Unix +uname+ command to provide
    # basic information about the platform.
    class Uname < Struct
      depends_on :programs => %w(uname)

      def suitability(method, *args) # :nodoc:
        # Level must be greater than Struct's
        return available? ? 2 : 0
      end

      def setup(opts={}) # :nodoc:
        super(opts)
        if available?
          @struct[:os]   ||= @@struct_cache[:os]   ||= `uname -s`.chomp.downcase
          @struct[:arch] ||= @@struct_cache[:arch] ||= `uname -m`.chomp.downcase
        end
      end
    end
  end
end
