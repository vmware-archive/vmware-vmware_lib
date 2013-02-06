#!/usr/bin/env rspec

require 'spec_helper'
require 'puppet_x/puppetlabs/transport'

module PuppetX::Puppetlabs::Transport
  class Dummy
    attr_reader :name, :user, :password, :host

    def initialize(option)
      @name     = option[:name]
      @user     = option[:username]
      @password = option[:password]
      @host     = option[:server]
    end

    def connect
    end

  end
end


describe PuppetX::Puppetlabs::Transport do

  before(:all) do
    @catalog = Puppet::Resource::Catalog.new
    ('a'..'c').to_a.each do |x|
      @catalog.add_resource(Puppet::Type.type(:transport).new({
        :name => "conn_#{x}",
        :username => "user_#{x}",
        :password => "pass_#{x}",
        :server   => "server_#{x}",
      }))
    end
  end

  it 'should discover and initialize transport resource' do
    @dummy = PuppetX::Puppetlabs::Transport.retrieve(:resource_ref => "Transport[conn_a]", :catalog => @catalog, :provider => 'dummy')
    @dummy.class.should == PuppetX::Puppetlabs::Transport::Dummy
    @dummy.name.should == 'conn_a'
    @dummy.user.should == 'user_a'
    @dummy.password.should == 'pass_a'
    @dummy.host.should == 'server_a'
  end

  it 'should reuse transport resource' do
    dummy1 = PuppetX::Puppetlabs::Transport.retrieve(:resource_ref => "Transport[conn_a]", :catalog => @catalog, :provider => 'dummy')
    dummy2 = PuppetX::Puppetlabs::Transport.retrieve(:resource_ref => "Transport[conn_a]", :catalog => @catalog, :provider => 'dummy')
    dummy1.should == dummy2
  end

  it 'should find existing transport resource' do
    dummy1 = PuppetX::Puppetlabs::Transport.retrieve(:resource_ref => "Transport[conn_a]", :catalog => @catalog, :provider => 'dummy')
    PuppetX::Puppetlabs::Transport.find('conn_a', 'dummy').should == dummy1
  end
end
