# VMware_Array support various forms of array comparison.
# :sort indicates whether the array values should be sorted prior to comparison
# :sort supports proc for custom sort such as:
# :sort => { |x, y| x.key <=> y.key }
#
# :inclusive indicates whether the array value is complete.
# :inclusive => :false intidates should values only need to be a subset of system value.
#
# Usage:
#   newproperty(:server_list, :array_matching => :all, :sort => :true,
#               :parent => Puppet::Property::VMware_Array) { }
class Puppet::Property::VMware_Array < Puppet::Property::VMware
  # Something internally converts false boolean to true, so using symbols.
  def self.sort
    @sort ||= :true
  end

  def self.sort=(value)
    raise Puppet::Error, 'VMWare_Array sort property must be :true, :false, or Proc.' unless (is_symbool? value) || (value.is_a? Proc)
    @sort = value
  end

  def self.inclusive
    @inclusive ||= :true
  end

  def self.inclusive=(value)
    raise Puppet::Error, 'VMWare_Array inclusive property must be :true or :false.' unless is_symbool? value
    @inclusive = value
  end

  def insync?(is)
    # Handle the case when the current value is nil.
    # If the provider expects array property nil == [], it should return [] in the property getter.
    return @should.nil? if is.nil?

    inclusive = self.class.inclusive == :true
    # Allow resources to override inclusive behavior
    inclusive = self.resource.value('inclusive') == true unless self.resource.value('inclusive').nil?

    if inclusive
      case self.class.sort
      when :true
        is.sort == @should.sort
      when :false
        is == @should
      when Proc
        is.send(:sort, &self.class.sort) == @should.send(:sort, &self.class.sort)
      end
    else
      (@should - is).empty?
    end
  end
end
