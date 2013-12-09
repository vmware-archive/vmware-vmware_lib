# Copyright (C) 2013 VMware, Inc.
require 'spec_helper'
require 'puppet/property/vmware'

describe Puppet::Property::VMware_Array do
  before(:each) do
    Puppet::Property::VMware_Array.initvars
    @resource = stub 'resource', :[]= => nil, :property => nil, :value => nil
    @property = Puppet::Property::VMware_Array.new(:resource => @resource)
    @provider = mock("provider")
    @property.stubs(:provider).returns(@provider)
    @property.stubs(:name).returns(:prop_name)
  end

  it 'should have default inclusive and sort settings' do
    @property.class.inclusive.should == :true
    @property.class.sort.should == :true
  end

  it 'should by return true for unordered array by default' do
    @property.should = ['c', 'b', 'a']
    @property.insync?(['a', 'b', 'c']).should == true
  end

  it 'should by return false for unmatched array' do
    @property.should = ['d', 'b', 'a']
    @property.insync?(['a', 'b', 'c']).should == false
  end

  it 'should by return false for unordered array if sort is false' do
    @property.should = ['c', 'b', 'a']
    @property.class.sort = :false
    @property.insync?(['a', 'b', 'c']).should == false
  end

  it 'should by return true for non-inclusive subset list' do
    @property.should = ['a', 'b']
    @property.class.inclusive = :false
    @property.insync?(['a', 'b', 'd']).should == true
  end

  it 'should by return false for non-inclusive subset when resource override inclusive true' do
    @resource.stubs(:value){'inclusive'}.returns(true)
    @property.should = ['a', 'b']
    @property.class.inclusive = :false
    @property.insync?(['a', 'b', 'd']).should == false
  end

  it 'should by return true for non-inclusive subset when resource override inclusive false' do
    @resource.stubs(:value){'inclusive'}.returns(false)
    @property.should = ['a', 'b']
    @property.insync?(['a', 'b', 'd']).should == true
  end
end

