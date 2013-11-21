class Puppet::Property::VMware_Hash < Puppet::Property::VMware
  def munge(value)
    camel_munge value
  end

  def insync?(current)
    desire = @should.first
    current ||= {}
    hash_subset?(desire, current)
  end
end
