require 'puppetlabs_spec_helper/module_spec_helper'
require 'pathname'

path = File.join(Pathname.new(__FILE__).parent, 'fixtures/modules')
Puppet[:modulepath] = path
