#!/usr/bin/env rspec

require 'spec_helper'
# Attempting to coerce 2.7.23
require 'pathname' # WORK_AROUND #14073 and #7788
mod = Puppet::Module.find('stdlib', Puppet[:environment].to_s)
require File.join mod.path, 'lib/puppet/type/file_line'

describe Puppet::Type.type(:file_line).provider(:ssh) do
  context 'when adding lines to file' do
    let :resource do
      Puppet::Type::File_line.new({
        :name => 'foo',
        :path => '/tmp/foo',
        :line => 'foo',
        :provider => 'ssh'
      })
    end

    let(:provider) { resource.provider }

    before do
      @ssh = mock('ssh')
      provider.class.stubs(:transport).returns(@ssh)
    end

    it 'should detect if the line exists in the file' do
      @ssh.stubs(:exec!).with('cat /tmp/foo').returns "bar\nfoo\nbaz"
      provider.exists?.should be_true
    end

    it 'should detect if the line does not exists in the file' do
      @ssh.stubs(:exec!).with('cat /tmp/foo').returns "bar\nbaz"
      provider.exists?.should be_nil
      @ssh.expects(:exec!).once
      provider.create
    end
  end

  context 'when matching' do
    let :resource do
      Puppet::Type::File_line.new({
        :name => 'foo',
        :path => '/tmp/foo',
        :line => 'key = foo',
        :match => '^key',
        :provider => 'ssh'
      })
    end

    let(:provider) { resource.provider }

    before do
      @ssh = mock('ssh')
      provider.class.stubs(:transport).returns(@ssh)
    end

    it 'should detect if the line exists in the file' do
      @ssh.stubs(:exec!).with('cat /tmp/foo').returns "bar\nkey = foo\nbaz"
      provider.exists?.should be_true
    end

    it 'should detect if the line does not exists and append' do
      @ssh.stubs(:exec!).with('cat /tmp/foo').returns "bar\nbaz"
      provider.exists?.should be_nil
      provider.expects(:append_line).once
      provider.create
    end

    it 'should detect if the line exists and replace' do
      @ssh.stubs(:exec!).with('cat /tmp/foo').returns "bar\nkey = hi\nbaz"
      provider.exists?.should be_nil
      @ssh.expects(:exec!).once
      provider.expects(:append_line).never
      provider.create
    end
  end
end
