#!/usr/bin/env rspec

require 'spec_helper'

describe Puppet::Type.type(:service).provider(:ssh) do
  context 'when configuring remote services' do
    let :resource do
      Puppet::Type::Service.new({
        :name => 'foo',
        :ensure => 'running',
        :provider => 'ssh'
      })
    end

    let(:provider) { resource.provider }

    before do
      @ssh = mock('ssh')
      provider.class.stubs(:transport).returns(@ssh)
    end

    it 'should detect if the service is running' do
      @ssh.stubs(:exec!).with('/etc/init.d/foo status; echo $?').returns "foo is running\n0"
      provider.status.should == :running
    end

    it 'should detect if the line does not exists in the file' do
      @ssh.stubs(:exec!).with('/etc/init.d/foo status; echo $?').returns "foo is stopped\n2"
      provider.status.should == :stopped
      @ssh.expects(:exec!).with('/etc/init.d/foo start')
      provider.start
    end
  end

  context 'when custom commands are provided' do
    let :resource do
      Puppet::Type::Service.new({
        :name => 'foo',
        :ensure => 'running',
        :start => 'service foo start',
        :status => 'service foo status',
        :provider => 'ssh'
      })
    end

    let(:provider) { resource.provider }

    before do
      @ssh = mock('ssh')
      provider.class.stubs(:transport).returns(@ssh)
    end

    it 'should detect if the service is running' do
      @ssh.stubs(:exec!).with('service foo status; echo $?').returns "foo is running\n0"
      provider.status.should == :running
    end

    it 'should detect if the line does not exists in the file' do
      @ssh.stubs(:exec!).with('service foo status; echo $?').returns "foo is stopped\n2"
      provider.status.should == :stopped
      @ssh.expects(:exec!).with('service foo start')
      provider.start
    end
  end
end
