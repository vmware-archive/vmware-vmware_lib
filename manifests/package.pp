# Copyright (C) 2013 VMware, Inc.
class vmware_lib::package (
) inherits vmware_lib::params {

  # net-ssh gem 2.1.4 (PE3) is incompatible with vcsa 5.5 security settings:
  package { 'net-ssh':
    ensure   => '2.7.0',
    provider => $::vmware_lib::params::provider,
  }

  package { 'net-scp':
    ensure   => '1.1.2',
    provider => $::vmware_lib::params::provider,
  }

  # hashdiff 1.0.0 is not compatible with PE
  package { 'hashdiff':
    ensure   => '0.0.6',
    provider => $::vmware_lib::params::provider,
  }

}
