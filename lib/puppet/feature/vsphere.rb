require 'puppet/util/feature'

Puppet.features.add(:vsphere, :libs => %w{rbvmomi})
