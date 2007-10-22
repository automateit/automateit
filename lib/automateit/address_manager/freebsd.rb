# == AddressManager::FreeBSD
#
# A FreeBSD-specific driver for the AddressManager provides complete support for
# querying, adding and removing addresses.
class AutomateIt::AddressManager::FreeBSD < AutomateIt::AddressManager::BaseDriver
  def self.token
    :freebsd
  end

  depends_on :programs => %w(ifconfig uname),
    :callbacks => lambda{`uname -s`.match(/freebsd/i)}

  def suitability(method, *args) # :nodoc:
    # Must be higher than ::BSD
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

  def _freebsd_ifconfig_helper(action, opts)
    # ifconfig fxp0 inet 172.16.1.3 netmask 255.255.255.255 alias
    opts2 = opts.clone
    is_alias = opts2.delete(:label)
    
    cmd = _ifconfig_helper(action, opts2)
    replacement = "inet"
    if is_alias
      cmd.gsub!(/ (up|down)$/, '')

      case action
      when :add
        replacement << " alias" 
      when :remove
        replacement << " -alias"
      else
        raise ArgumentError.new("Unknown action: #{action}")
      end
    end
    cmd.gsub!(/(ifconfig\s+[^\s]+\s+)/, '\1'+replacement+' ')
    
    return cmd
  end
end
