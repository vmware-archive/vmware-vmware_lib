# Copyright (C) 2013 VMware, Inc.
Puppet::Type.newtype(:transport) do
  @doc = "Manage transport connectivity info such as username, password, server."

  newparam(:name, :namevar => true) do
    desc "The name of the network transport."
  end

  newparam(:username) do
  end

  newparam(:password) do
  end

  newparam(:server) do
    defaultto('localhost')
  end

  newparam(:options) do
    validate do |value|
      fail("Option value must be a hash.") unless value.is_a? ::Hash
    end
    defaultto({})
  end
end

Puppet::Type.newmetaparam(:transport) do
  desc "Provide a new metaparameter for all resources called transport."
end
