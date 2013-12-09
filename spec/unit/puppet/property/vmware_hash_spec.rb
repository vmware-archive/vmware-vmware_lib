# Copyright (C) 2013 VMware, Inc.

require 'spec_helper'
require 'puppet/property/vmware'

describe Puppet::Property::VMware_Hash do
  before(:each) do
    Puppet::Property::VMware_Hash.initvars
    @resource = stub 'resource', :[]= => nil, :property => nil
    @property = Puppet::Property::VMware_Hash.new(:resource => @resource)
    @provider = mock("provider")
    @property.stubs(:provider).returns(@provider)
    @property.stubs(:name).returns(:prop_name)
  end

  it 'should by return true for matching hash' do
    @property.should = {'a' => 1, 'b' => 2 }
    @property.insync?({'b' => 2, 'a' => 1}).should == true
  end

  it 'should by return false for mismatching hash' do
    @property.should = {'a' => 1, 'b' => 2 }
    @property.insync?({'a' => 2, 'b' => 2}).should == false
  end

  it 'should by return true for subset of hash' do
    @property.should = {'a' => {'c' => 1}, 'b' => 2 }
    @property.insync?({'b' => 2, 'a' => {'c' => 1}, 'd' => 3}).should == true
  end

  it 'should by return true for subset of deep hash' do
    @property.should = {'a' => {'c' => [1, 2]}, 'b' => 2 }
    @property.insync?({'a' => {'c' => [1, 2, 3]}, 'b' => 2}).should == true
  end
end
