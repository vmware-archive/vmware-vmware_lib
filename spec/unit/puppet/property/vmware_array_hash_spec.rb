# Copyright (C) 2013 VMware, Inc.
require 'spec_helper'
require 'puppet/property/vmware'

describe Puppet::Property::VMware_Array_Hash do
  before(:each) do
    Puppet::Property::VMware_Array_Hash.initvars
    @resource = stub 'resource', :[]= => nil, :property => nil
    @property = Puppet::Property::VMware_Array_Hash.new(:resource => @resource)
    @provider = mock("provider")
    @property.stubs(:provider).returns(@provider)
    @property.stubs(:name).returns(:prop_name)
  end

  it 'should accept have default comparison hash key' do
    @property.class.key.should == 'name'
  end

  it 'should return true for matching array of hashes' do
    @property.should = [{'name' => 'a', 'val' => 1}]
    @property.insync?([{'name' => 'a', 'val' => 1}]).should == true
  end

  it 'should return true for subset of array of hashes' do
    @property.should = [{'name' => 'a', 'val' => 1}, {'name' => 'b', 'val' => 2}]
    @property.insync?([{'name' => 'a', 'val' => 1}, {'name' => 'b', 'val' => 2}, {'name' => 'c'}]).should == true
    @property.should = [{'name' => 'a', 'val' => 1}, {'name' => 'b', 'val' => 2}]
    @property.insync?([{'name' => 'a', 'val' => 1}, {'name' => 'b', 'val' => 2, 'baz' => 3}]).should == true
  end

  it 'should return false for non-subset of array of hashes' do
    @property.should = [{'name' => 'a', 'val' => 1}, {'name' => 'b', 'val' => 2, 'baz' => 3}]
    @property.insync?([{'name' => 'a', 'val' => 1}, {'name' => 'b', 'val' => 2}]).should == false
  end

  it 'should accept different comparison hash key' do
    @property.should = [{'bar' => 'a', 'val' => 1}]
    @property.class.key = 'bar'
    @property.insync?([{'bar' => 'a', 'val' => 1}]).should == true
  end
end
