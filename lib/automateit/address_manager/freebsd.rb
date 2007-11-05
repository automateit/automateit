# == AddressManager::FreeBSD
#
# A FreeBSD-specific driver for the AddressManager provides complete support for
# querying, adding and removing addresses.
class AutomateIt::AddressManager::FreeBSD < AutomateIt::AddressManager::BaseDriver
  def self.token
    :freebsd
  end

  depends_on :programs => %w(ifconfig uname),
    :callbacks => lambda{`uname -s 2>&1`.match(/freebsd/i)}

  def suitability(method, *args) # :nodoc:
    # Must be higher than AddressManager::BSD
    available? ? 3 : 0
  end

  # See AddressManager#add
  def add(opts)
    _add_helper(opts) do |opts|
      interpreter.sh(_freebsd_ifconfig_helper(:add, opts))
    end
  end

  # See AddressManager#remove
  def remove(opts)
    _remove_helper(opts) do |opts|
      interpreter.sh(_freebsd_ifconfig_helper(:remove, opts))
      true
    end
  end
  
  # See AddressManager#has?
  def has?(opts)
    opts2 = opts.clone
    is_alias = opts2.delete(:label)
    return super(opts2)
  end
  
protected

  # ifconfig fxp0 inet 172.16.1.3 netmask 255.255.255.255 alias
  def _freebsd_ifconfig_helper(action, opts)    
    helper_opts = {:state => false, :prepend => %w(inet)}
    opts2 = opts.clone
    if opts2.delete(:label)
      helper_opts[:append] = \
        case action
        when :add: %w(alias)
        when :remove, :del: %w(-alias)
        else ArgumentError.new("Unknown action: #{action}")
        end
    end
    return _ifconfig_helper(action, opts2, helper_opts)
  end
end
