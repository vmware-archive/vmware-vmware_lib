#!/usr/bin/env rspec

require 'spec_helper'
require 'puppet/property/vmware'

describe Puppet::Property::VMware do
  before(:each) do
    Puppet::Property::VMware.initvars
    @resource = stub 'resource', :[]= => nil, :property => nil
    @property = Puppet::Property::VMware.new(:resource => @resource)
  end

  it 'should camelize snake_case keys for a nested hash' do
    @property.camel_munge({'snake_case' => {'lower_case'=>'val'}}).should == {'snakeCase' => {'lowerCase' => 'val'}}
  end
end

# TODO: Have issues assigning property.should=(val) and testing insync?
#describe Puppet::Property::VMware::Hash do
#end
#
#describe Puppet::Property::VMware::Array do
#end
