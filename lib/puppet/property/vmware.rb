# Copyright (C) 2013 VMware, Inc.
require 'hashdiff'
require 'pathname' # WORK_AROUND #14073 and #7788
module_lib = Pathname.new(__FILE__).parent.parent.parent
require File.join module_lib, 'puppet_x/vmware/util'

class Puppet::Property::VMware < Puppet::Property

  include PuppetX::VMware::Util

  def camel_munge(value, uppercase = false)
    case value
    when Hash
      value.each do |k, v|
        camel_k = PuppetX::VMware::Util.camelize(k, :lower)
        value[camel_k] = camel_munge v
        value.delete k unless k == camel_k
      end
      value
    else
      value
    end
  end

  def camel_name
    PuppetX::VMware::Util.camelize(self.class.name, :lower)
  end
end

class Puppet::Property::VMware_Hash < Puppet::Property::VMware
  def munge(value)
    value = camel_munge(value)
  end

  def is_to_s(v)
    v.inspect
  end

  def should_to_s(v)
    v.inspect
  end

  def insync?(current)
    desire = @should.first
    current ||= {}
    diff = HashDiff.diff(desire, current)
    diff.empty? or diff.select{|x| x.first != '+'}.empty?
  end
end

# VMware_Array support various forms of array comparison.
# :sort indicates whether the array values should be sorted prior to comparison
# :sort supports proc for custom sort such as:
# :sort => { |x, y| x.key <=> y.key }
#
# :inclusive indicates whether the array value is complete.
# :inclusive => :false intidates should values only need to be a subset of system value.
#
# Usage:
#   newproperty(:server_list, :array_matching => :all, :sort => :true,
#               :parent => Puppet::Property::VMware_Array) { }
class Puppet::Property::VMware_Array < Puppet::Property::VMware
  # Something retarded internally converts false boolean to true, so using symbols.
  def self.sort
    @sort ||= :true
  end

  def self.sort=(value)
    raise Puppet::Error, 'VMWare_Array sort property must be :true, :false, or Proc.' unless ([:true, :false].include? value) || (value.is_a? Proc)
    @sort = value
  end

  def self.inclusive
    @inclusive ||= :true
  end

  def self.inclusive=(value)
    raise Puppet::Error, 'VMWare_Array inclusive property must be :true or :false.' unless [:true, :false].include? value
    @inclusive = value
  end

  def is_to_s(v)
    v.inspect
  end

  def should_to_s(v)
    v.inspect
  end

  def insync?(is)
    # Handle the case when the current value is nil.
    # If the provider expects array property nil == [], it should return [] in the property getter.
    return @should.nil? if is.nil?

    if self.class.inclusive == :true
      case self.class.sort
      when :true
        is.sort == @should.sort
      when :false
        is == @should
      when Proc
        is.send(:sort, &self.class.sort) == @should.send(:sort, &self.class.sort)
      end
    else
      (@should - is).empty?
    end
  end
end

# Handle properties that are an Array of Hashes and each hash have a lookup key.
# By default name is the primary key for each hash (their values should be unique):
# [ { 'name' => 'a', 'val' => '5' }, { 'name' => 'b', 'val' => '5' } ]
#
# Usage:
#   newproperty(:server_list, :array_matching => :all, :key => 'ipAddress',
#               :parent => Puppet::Property::VMware_Array_Hash) { }
class Puppet::Property::VMware_Array_Hash < Puppet::Property::VMware_Array
  def self.key
    @key ||= 'name'
  end

  def self.key=(value)
    @key = value
  end

  def is_to_s(v)
    v.inspect
  end

  def should_to_s(v)
    v.inspect
  end

  def insync?(is)
    return @should.nil? if is.nil?
    key = self.class.key

    @should.each do |h|
      begin
        match = is.find_all{|x| x[key] == h[key]}
        return false unless match.size == 1
        diff = HashDiff.diff(h, match.first)
        return false unless diff.empty? or diff.select{|x| x.first != '+'}.empty?
      rescue
        return false
      end
    end
    true
  end
end
