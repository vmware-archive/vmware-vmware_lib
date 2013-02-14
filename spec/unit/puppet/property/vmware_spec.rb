#!/usr/bin/env rspec
# Copyright (C) 2013 VMware, Inc.

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

describe Puppet::Property::VMware_Array do
  before(:each) do
    Puppet::Property::VMware_Array.initvars
    @resource = stub 'resource', :[]= => nil, :property => nil
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
end

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
