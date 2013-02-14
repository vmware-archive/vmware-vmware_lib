# Copyright (C) 2013 VMware, Inc.
require 'puppet/util/feature'

Puppet.features.add(:vsphere, :libs => %w{rbvmomi})
