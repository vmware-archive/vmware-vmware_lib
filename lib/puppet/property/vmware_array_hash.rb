# Handle properties that are an Array of Hashes and each hash have a lookup key.
# By default name is the primary key for each hash (their values should be unique):
# [ { 'name' => 'a', 'val' => '5' }, { 'name' => 'b', 'val' => '5' } ]
#
# Usage:
#   newproperty(:server_list, :array_matching => :all, :key => 'ipAddress',
#               :parent => Puppet::Property::VMware_Array_Hash) { }

class Puppet::Property::VMware_Array_Hash < Puppet::Property::VMware_Array
  def munge(value)
    PuppetX::VMware::Util.string_keys(value)
  end

  def self.inclusive
    @inclusive ||= :false
  end

  def self.inclusive=(value)
    raise Puppet::Error, 'VMWare_Array inclusive property must be :true or :false.' unless is_symbool? value
    @inclusive = value
  end

  def self.preserve
    @preserve ||= :false
  end

  def self.preserve=(value)
    raise Puppet::Error, 'VMWare_Array preserve property must be :true or :false.' unless is_symbool? value
    @preserve = value
  end

  def self.key
    @key ||= 'name'
  end

  def self.key=(value)
    @key = value
  end

  def match_subset(should, is, key)
    should.each do |h|
      begin
        match = is.find_all{|x| x[key] == h[key]}
        return false unless match.size == 1
        return false unless hash_subset?(h, match.first)
      rescue
        return false
      end
    end
    true
  end

  def merge_to_preserve should, is, key
    # turn arrays into hashes with appropriate key
    h_should = Hash[should.map{|element| [(element.fetch key), element]}]
    h_is     = Hash[    is.map{|element| [(element.fetch key), element]}]
    # merge, giving priority to 'should' ; map values to array
    (h_is.merge h_should).values
  end

  def insync?(is)
    return @should.nil? if is.nil?
    key = self.class.key

    inclusive = self.class.inclusive == :true
    preserve  = self.class.preserve  == :true
    # Allow resources to override inclusive behavior
    inclusive = self.resource.value('inclusive') == :true unless self.resource.value('inclusive').nil?
    preserve  = self.resource.value('preserve')  == :true unless self.resource.value('preserve').nil?

    if inclusive
      match_subset(@should, is, key) and match_subset(is, @should, key)
    else
      value = match_subset(@should, is, key)
      (@should = merge_to_preserve @should, is, key) if preserve
      Puppet.debug "vmware_array_hash insync has match_subset <#{value.inspect}>, preserve <#{preserve}>, is <#{is.inspect}>, @should <#{@should}>"
      value
    end
  end
end
