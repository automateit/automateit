# == AddressManager::OpenBSD
#
# A OpenBSD-specific driver for the AddressManager provides complete support for
# querying, adding and removing addresses.
class AutomateIt::AddressManager::OpenBSD < AutomateIt::AddressManager::BaseDriver
  def self.token
    :openbsd
  end

  depends_on :programs => %w(ifconfig uname),
    :callbacks => lambda{`uname -s 2>&1`.match(/openbsd/i)}

  def suitability(method, *args) # :nodoc:
    # Must be higher than AddressManager::BSD
    available? ? 3 : 0
  end

  # See AddressManager#add
  def add(opts)
    _add_helper(opts) do |opts|
      interpreter.sh(_openbsd_ifconfig_helper(:add, opts))
    end
  end

  # See AddressManager#remove
  def remove(opts)
    _remove_helper(opts) do |opts|
      interpreter.sh(_openbsd_ifconfig_helper(:remove, opts))
      true
    end
  end
  
  # See AddressManager#addresses
  def addresses()
    _raise_unless_available
    # OpenBSD requires an "-A" to display aliases, not the usual "-a"
    return `ifconfig -A`.scan(/\s+inet\s+([^\s]+)\s+/).flatten
  end
  
  # See AddressManager#has?
  def has?(opts)
    opts2 = opts.clone
    is_alias = opts2.delete(:label)
    return super(opts2)
  end
  
protected

  # ifconfig dc0 inet alias 192.168.0.3 netmask 255.255.255.255
  def _openbsd_ifconfig_helper(action, opts)
    helper_opts = {:state => false, :prepend => %w(inet)}
    opts2 = opts.clone
    if opts2.delete(:label)
      helper_opts[:prepend] << \
        case action
        when :add
          "alias"
        when :remove, :del
          "delete"
        else 
          ArgumentError.new("Unknown action: #{action}")
        end
    end
    return _ifconfig_helper(action, opts2, helper_opts)
  end
end
