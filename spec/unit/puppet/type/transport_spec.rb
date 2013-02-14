#!/usr/bin/env rspec
# Copyright (C) 2013 VMware, Inc.

require 'spec_helper'

transport = Puppet::Type.type(:transport)

describe transport do
  before :each do
    @transport = transport
    @provider = stub 'provider'

    @resource = @transport.new({
      :name     => 'telnet',
      :username => 'root',
      :password => 'pass',
      :server   => '127.0.0.1',
    })
  end

  it 'should have name as :namevar.' do
    @transport.key_attributes.should == [:name]
  end

  it 'should have empty hash as default for options' do
    @resource[:options].should == {}
  end

  it 'should accept hash value for options' do
    @resource[:options] = { 'timeout' => 30 }
    @resource[:options].should == { 'timeout' => 30 }
  end

  it 'should reject non-hash value for options' do
   expect{ @resource[:options] = 50}.to raise_error
  end
end
