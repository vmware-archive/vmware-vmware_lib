# Copyright (C) 2013 VMware, Inc.
require 'puppet/util/feature'

Puppet.features.add(:restclient, :libs => %w{rest_client})
