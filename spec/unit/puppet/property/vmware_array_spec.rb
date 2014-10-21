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

  it 'should have default inclusive, preserve, and sort settings' do
    @property.class.inclusive.should == :true
    @property.class.preserve.should == :false
    @property.class.sort.should == :true
  end

  it 'should return true for unordered array with matching elements by default' do
    @property.should = ['c', 'b', 'a']
    @property.insync?(['a', 'b', 'c']).should == true
  end

  it 'should return false for unmatched array' do
    @property.should = ['d', 'b', 'a']
    @property.insync?(['a', 'b', 'c']).should == false
  end

  it 'should return false for unordered array with matching elements if sort is :false' do
    @property.should = ['c', 'b', 'a']
    @property.class.sort = :false
    @property.insync?(['a', 'b', 'c']).should == false
  end

  it 'should return true for non-inclusive subset if class inclusive is :false' do
    @property.should = ['a', 'b']
    @property.class.inclusive = :false
    @property.insync?(['a', 'b', 'd']).should == true
  end

  it 'should return false and union current and desired sets when class inclusive is :false and preserve is :true' do
    @property.class.inclusive = :false
    @property.class.preserve  = :true
    @property.should = ['a', 'c']
    @property.insync?(['a', 'b', 'd']).should == false
    @property.should_for_spec.sort.should == ['a', 'b', 'c', 'd']
  end

  it 'should return false for non-inclusive subset when resource override inclusive :true' do
    @property.class.inclusive = :false # be sure overrides are overriding
    @property.class.preserve  = :false # be sure overrides are overriding
    @resource.stubs(:value).at_least(2).with('inclusive').returns(:true)
    @resource.stubs(:value).at_least(2).with('preserve' ).returns(:true)
    @resource.value('inclusive').should == :true
    @resource.value('preserve' ).should == :true
    @property.should = ['a', 'b']
    @property.insync?(['a', 'b', 'd']).should == false
  end

  it 'should return true for non-inclusive subset when resource override inclusive :false' do
    @property.class.inclusive = :true  # be sure overrides are overriding
    @property.class.preserve  = :false # be sure overrides are overriding
    @resource.stubs(:value).at_least(2).with('inclusive').returns(:false)
    @resource.stubs(:value).at_least(2).with('preserve' ).returns(:true)
    @resource.value('inclusive').should == :false
    @resource.value('preserve' ).should == :true
    @property.should = ['a', 'b']
    @property.insync?(['a', 'b', 'd']).should == true
  end

  it 'should return false and union current and desired sets when resource override inclusive is :false and preserve is :true' do
    @property.class.inclusive = :true  # be sure overrides are overriding
    @property.class.preserve  = :false # be sure overrides are overriding
    @resource.stubs(:value).at_least(2).with('inclusive').returns(:false)
    @resource.stubs(:value).at_least(2).with('preserve' ).returns(:true)
    @resource.value('inclusive').should == :false
    @resource.value('preserve' ).should == :true
    @property.should = ['a', 'c']
    @property.insync?(['a', 'b', 'd']).should == false
    @property.should_for_spec.sort.should == ['a', 'b', 'c', 'd']
  end

  it 'should return false and ignore current set when resource override inclusive is :false and preserve is :false' do
    @property.class.inclusive = :true  # be sure overrides are overriding
    @property.class.preserve  = :true  # be sure overrides are overriding
    @resource.stubs(:value).at_least(2).with('inclusive').returns(:false)
    @resource.stubs(:value).at_least(2).with('preserve' ).returns(:false)
    @resource.value('inclusive').should == :false
    @resource.value('preserve' ).should == :false
    @property.should = ['a', 'c']
    @property.insync?(['a', 'b', 'd']).should == false
    @property.should_for_spec.sort.should == ['a', 'c']
  end

end
