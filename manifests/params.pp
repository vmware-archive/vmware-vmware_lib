# Copyright (C) 2013 VMware, Inc.
# vmware_lib common parameters
class vmware_lib::params {

  if $::puppetversion =~ /Puppet Enterprise/ {
    $provider  = 'pe_gem'
    $ruby_path = '/opt/puppet/bin/ruby'
  } else {
    $provider  = 'gem'
    $ruby_path = '/usr/bin/env ruby'
  }

}
