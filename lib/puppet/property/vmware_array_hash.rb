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

  def self.key
    @key ||= 'name'
  end

  def self.key=(value)
    @key = value
  end

  def insync?(is)
    return @should.nil? if is.nil?
    key = self.class.key

    @should.each do |h|
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
end
