require 'puppetlabs_spec_helper/module_spec_helper'
require 'pathname'

# Set Ruby load paths for the fixtures, just setting Puppet modulepath is not enough
[ 'stdlib', 'vmware_lib' ].each do |mod|
  $:.unshift File.dirname(__FILE__) + "/fixtures/modules/#{mod}/lib"
end



