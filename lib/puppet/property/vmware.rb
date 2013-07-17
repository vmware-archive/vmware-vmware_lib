# Copyright (C) 2013 VMware, Inc.
require 'set'
require 'rbvmomi'
require 'hashdiff'

begin
  require 'puppet_x/vmware/util'
rescue LoadError => e
  require 'pathname' # WORK_AROUND #14073 and #7788
  module_lib = Pathname.new(__FILE__).parent.parent.parent
  require File.join module_lib, 'puppet_x/vmware/util'
end

class Puppet::Property::VMware < Puppet::Property
  include PuppetX::VMware::Util

  # Public: converts system value to puppet output string.
  #
  # value - data to format.
  #
  # Returns: string or object.inspect.
  def is_to_s(value)
    case value
    when String
      value
    else
      value.inspect
    end
  end

  # Public: converts desire value to puppet output string.
  #
  # value - data to format.
  #
  # Returns: string or object.inspect.
  def should_to_s(value)
    case value
    when String
      value
    else
      value.inspect
    end
  end

  # Internal: munges hashes to ensure keys are camel case.
  #
  # value - the value to munge.
  # first_letter - the case of the first letter, default :lower.
  #
  # Examples:
  #
  #   camel_munge('bar')
  #   # => 'bar'
  #
  #   camel_munge({:big_box => { :fun => 3 }})
  #   # => {:bigBox => {:fun => 3}}
  #
  # Returns: hash with all key camel case, or original value if it's not hash.
  def camel_munge(value, first_letter = :lower)
    case value
    when Hash
      result = {}
      value.each do |k, v|
        camel_key = PuppetX::VMware::Util.camelize(k, first_letter)
        result[camel_key] = camel_munge v
      end
      result
    else
      value
    end
  end

  # Internal: return the property name in camel case.
  #
  # Examples:
  #
  #   newproperty(:host_name, :parent => Puppet::Property::VMware) do
  #   ...
  #   end
  #   @property.camel_name
  #   # => 'hostName'
  #
  # Returns string
  def camel_name
    PuppetX::VMware::Util.camelize(self.class.name, :lower)
  end

  # Internal: evaluates whether the second hash is a superset of the first.
  #
  # subset - the hash which should be a subset.
  # superset - the hash which should be a superset.
  #
  # Examples:
  #
  #   hash_inclusive?({:a=>1}, {:b=>2, :a=>1})
  #   # => true
  #
  #   hash_inclusive?({:a=>1}, {:b=>1})
  #   # => false
  #
  # Returns boolean
  def hash_subset?(subset, superset)
    diff = HashDiff.diff(subset, superset)
    diff.empty? or diff.select{|x| x.first != '+'}.empty?
  end

  # Internal: is the value :true or :false or symbool, the unicorn of puppet boolean.
  # value - value to check.
  #
  # Examples:
  #
  #    is_symbool? :false
  #    # => true
  #
  # Returns boolean
  def self.is_symbool?(value)
    [:true, :false].include? value
  end

  def is_symbool?(value)
    self.class.is_symbool(value)
  end

  # Internal: is the value an Integer or string Integer, the joy of puppet manifest and ENC inconsistencies, see #21807.
  # value - value to check.
  #
  # Examples:
  #
  #    is_stringint? '15'
  #    # => true
  #
  # Returns boolean
  def self.is_stringint?(value)
    case value
    when Integer
      true
    when String
      Integer(value) rescue false
      true
    else
      false
    end
  end
end

require_relative 'vmware_hash'
require_relative 'vmware_array'
require_relative 'vmware_array_hash'
require_relative 'vmware_array_vim_object'
