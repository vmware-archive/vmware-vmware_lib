#!/usr/bin/env rspec

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
end
