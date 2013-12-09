#!/usr/bin/env rspec
# Copyright (C) 2013 VMware, Inc.

require 'spec_helper'
require 'puppet/property/vmware'

describe Puppet::Property::VMware do
  before(:each) do
    Puppet::Property::VMware.initvars
    @resource = stub 'demo_me', :[]= => nil, :property => nil
    @property = Puppet::Property::VMware.new(:resource => @resource)
  end

  it 'should return string for is_to_s should_to_s' do
    @property.is_to_s('hello').should == 'hello'
    @property.should_to_s('hello').should == 'hello'
  end

  it 'should format array for is_to_s should_to_s' do
    @property.is_to_s([1, 2, 3]).should == '[1, 2, 3]'
    @property.should_to_s({:a => 1}).should == '{:a=>1}'
  end

  it 'should camelize snake_case keys for a nested hash' do
    @property.camel_munge({'snake_case' => {'lower_case'=>'val'}}).
      should == {'snakeCase' => {'lowerCase' => 'val'}}
  end

  it 'should camelize snake_case keys for a nested hash with uppercase' do
    @property.camel_munge({'snake_case' => {'lower_case'=>'val'}}, :upper).
      should == {'SnakeCase' => {'LowerCase' => 'val'}}
  end

  it 'should evaluate hash_subset' do
    @property.hash_subset?({:a => 1}, {:b=>2, :a=>1}).should == true
    @property.hash_subset?({:a => 1}, {:b=>2}).should == false
    @property.hash_subset?({:a => 1}, {}).should == false
  end

  it 'should evaluate is_symbool?' do
    @property.is_symbool?(:false).should == true
    @property.is_symbool?(true).should == false
  end

  it 'should evaluate is_stringint?' do
    @property.is_stringint?('10').should == true
    @property.is_stringint?('10x').should == false
  end
end
