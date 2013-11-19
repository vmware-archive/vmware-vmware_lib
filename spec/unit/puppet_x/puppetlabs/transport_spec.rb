#!/usr/bin/env rspec
# Copyright (C) 2013 VMware, Inc.

require 'spec_helper'

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

    def close
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

  it 'should close any open connections' do
    dummy1 = PuppetX::Puppetlabs::Transport.retrieve(:resource_ref => "Transport[conn_a]", :catalog => @catalog, :provider => 'dummy')
    dummy2 = PuppetX::Puppetlabs::Transport.retrieve(:resource_ref => "Transport[conn_b]", :catalog => @catalog, :provider => 'dummy')
    dummy1.expects(:close)
    dummy2.expects(:close)
    PuppetX::Puppetlabs::Transport.cleanup
  end

  it 'should close connections after catalog apply' do
    PuppetX::Puppetlabs::Transport.expects(:cleanup)

    # catalog.apply writes result files, so testing with transaction directly.
    @transaction = nil
    begin
      @transaction = Puppet::Transaction.new(@catalog)
    rescue
      @transaction = Puppet::Transaction.new(@catalog, nil, nil)
    end
    @transaction.evaluate
  end
end
