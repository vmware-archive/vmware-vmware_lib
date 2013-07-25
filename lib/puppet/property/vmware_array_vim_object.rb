VIM = RbVmomi::VIM
ABSTRACT_CLASS = :ABSTRACT_CLASS
MO_KEY = :MO_KEY
# Handle properties that are an Array of vSphere API objects expressed as an
# Array of hashes. 
# By default name is the primary key for each hash (their values should be unique):
# [ { 'name' => 'a', 'val' => '5' }, { 'name' => 'b', 'val' => '5' } ]
#
# Usage:
#   newproperty(:server_list, :array_matching => :all, :key => 'ipAddress',
#               :parent => Puppet::Property::VMware_Array_VIM_Object) { }
class Puppet::Property::VMware_Array_VIM_Object < Puppet::Property::VMware_Array
  def self.key
    @key ||= 'name'
  end

  def self.key=(v)
    v = [v] unless v.instance_of? ::Array
    @key = v
  end

  def self.type
    @type ||
        fail("Custom property for #{self.name} "\
             "requires 'type' to be initialized")
  end

  def self.type=(v)
    @type = VIM.const_get(v.to_s.to_sym)
  end

  def self.comparison_scope
    @comparison_scope ||
        fail("Custom property for #{self.name} "\
             "requires 'comparison_scope' to be initialized")
  end

  def self.comparison_scope=(v)
    @comparison_scope = v
  end

  def self.sort_array
    @sort_array ||
        fail("Custom property for #{self.name} "\
             "requires 'sort_array' to be initialized")
  end

  def self.sort_array=(v)
    @sort_array = v
  end

  def munge(v)
    @should_premunge = v
  end

  def real_munge(v, type = self.class.type)
    Puppet.debug "vim munge enter: \"#{type}\", #{v.inspect}"

    # puppet calls munge for each array element, but
    # recursive calls may be made with entire array
    if v.is_a? ::Array
      x = v.map{|element| real_munge(element, type)}
    else
      # get properties' wsdl descriptions, inherited and added, as hash
      desc_by_name = Hash[*
        type.full_props_desc. # includes inherited properties
        map{|desc| [desc['name'].to_sym, desc]}.
        flatten
      ]

      # get hints and annotations for things not in wsdl
      ppft = puppet_properties_for_type type

      # dvswitch and its friends and relations don't use
      # mo_refs. well, they do. but the hard way... it's
      # up to us to _just_know_ which properties should
      # have mo_ref values in them, and which type they
      # should be...
      #
      # here we walk through and stuff mo_ref values
      # into the properties we have preknowledge of
      #
      if ppft.include? :mo_key
        pset = Set.new(v.keys)
        ppft[:mo_key].each{|mo_key|
          prop_name = mo_key[:property]
          if pset.include? prop_name
            v[prop_name] =
              resource.provider.mo_ref_by_name(
                :name => v[prop_name],
                :type => mo_key[:type],
                :scope => mo_key[:scope]
              ) || v[prop_name]
          end
        }
      end

      v.each_key do |v_key|
        unless prop_desc = desc_by_name[v_key.to_s.to_sym]
          fail "unexpected property for #{type}: #{v_key}"
        end

        wsdl_type = prop_desc["wsdl_type"]

        # recognize xsd types as strings
        if /^xsd:/.match wsdl_type
          case wsdl_type
          when 'xsd:int', 'xsd:short', 'xsd:long'
            v[v_key] = Integer(v[v_key])
          when 'xsd:string', 'xsd:boolean'
            v[v_key] = v[v_key]
          else
            fail "unexpected wsdl_type \"#{wsdl_type}\""
          end
        elsif (nested_type = preferred_class_by_class wsdl_type)
          if nested_type.kind == :managed
            # We can't finish munge at (puppet) 'compile' time because
            # we don't yet have a connection to the system to convert
            # Managed Object names to mo_refs and vice versa.

            v[v_key] = resource.provider.mo_ref_by_name(
              :name => v[v_key], :type => nested_type, :scope => :datacenter)
          else
            v[v_key] = real_munge v[v_key], nested_type
          end
        else
          fail "unexpected wsdl_type \"#{wsdl_type}\""
        end
      end

      x = type.new v # results in necessary bottom-up order
    end
    Puppet.debug "vim munge leave: #{x.inspect}"
    x

  end

  def hashify(v)
    # never modify the input; always create a copy
    if v.nil?
      return v
    elsif v.instance_of? ::Hash
      return Marshal.load(Marshal.dump(v))
    elsif v.instance_of? ::Array
      return v.map{|element| hashify element}
    end

    type = v.class
    ancestors = type.ancestors
    fail "hashify: unexpected class '#{type}':#{v.inspect}" unless
        ancestors.include? RbVmomi::BasicTypes::ObjectWithProperties

    # never modify the input; always create a copy
    v = {}.update v.props

    # remove cruft
    v.delete_if{|cruft_key,cruft_val| cruft_val.nil?}

    # remove cruft
    if ancestors.include? VIM::DynamicData
      [:dynamicProperty, :dynamicType].each do |prop_name|
        if v.include? prop_name
          v.delete(prop_name) if v[prop_name] == []
        end
      end
    end

    v.each_key do |prop_name|

      prop_desc = type.find_prop_desc(prop_name.to_s.to_sym)
      wsdl_type = prop_desc["wsdl_type"]
      next if wsdl_type =~ /^xsd:/ # nothing to do...

      # any non-VIM types must be handled here... not expected

      # handle VIM types
      nested_type = preferred_class_by_class wsdl_type
      if nested_type.nil?
        fail "#{v.inspect}: unexpected wsdl_type '#{wsdl_type}'"
      else
        if nested_type.kind == :managed
          # SWAG - all nested managed objects should be mo_ref
          v[prop_name] = v[prop_name]._ref unless
              String === v[prop_name]
        else
          v[prop_name] = hashify v[prop_name]
        end
      end

    end

  end

  def is_to_s(v)
    # fix up current value 'is' for this particular type
    # to make it readily comparable to @should
    type = self.class.type
    v = resource.provider.fixup_is(type, v, @should) if
        resource.provider.respond_to? :fixup_is
    hashify v
  end

  def should_to_s(v)
    hashify v
  end

=begin
  def change_to_s(is,should)
    "changed #{(is_to_s is).inspect} to #{(should_to_s should).inspect}"
  end
=end

  def insync?(is)
    return @should.nil? if is.nil?

    key = self.class.key
    type = self.class.type
    comparison_scope = self.class.comparison_scope

=begin

  Most vsphere subsystems have different classes to represent the
  current configuration and a desired new configuration.  These
  classes usually include 'info' in the current configuration's
  class name and 'spec' in the desired configuration's class
  name. Usually, the two classes can be found at the same location
  some overall structure.  This makes it fairly easy to compare
  'is' and 'should' values for Puppet's insync? method.

  When it comes to 'host members', the DistributedVirtualSwitch
  follows the pattern in its own way. There are two classes that
  are roughly comparable, in the usual way:

    DistributedVirtualSwitchHostMemberConfigSpec - desired
    DistributedVirtualSwitchHostMemberConfigInfo - current

  However, they are located in the larger DVSConfigInfo and
  DVSConfigSpec structures quite differently.  Each (non-array)
  DistributedVirtualSwitchHostMemberConfigInfo is the 'config'
  property of DistributedVirtualSwitchHostMember.

    DVSConfigInfo.host[]
          is type:           DistributedVirtualSwitchHostMember[]
    DVSConfigInfo.host[].config 
          is type:           DistributedVirtualSwitchHostMemberConfigInfo
    DVSConfigSpec.host[]
          is type:           DistributedVirtualSwitchHostMemberConfigSpec[]

  So to get current and desired values for Puppet insync? method, 
  type-specific rearrangement of the current values is required.

  This type-specific processing is relegated to the provider. If
  massaging of the current values is required for other vsphere 
  types, perhaps this scheme will be useful as a pattern.

=end

    # fix up current value 'is' for this particular type
    # to make it readily comparable to @should
    is = resource.provider.fixup_is(type, is, @should) if
        resource.provider.respond_to? :fixup_is

    # munge now that connection is available to turn
    # object names into managed object references

    x = case @should
        when nil
          nil
        when ::Array
          @should.map{|element| real_munge Marshal.load(Marshal.dump(element))}
        when ::Hash
          real_munge Marshal.load(Marshal.dump(@should))
        else
          fail "VMware_Array_VIM_Object: unexpected data: #{v.inspect}"
        end
    @should = x

    # turn arrays of objects into arrays of hashes
    aofh_is_now = hashify is
    aofh_should = hashify @should

    case comparison_scope
    when :array
      if self.class.sort_array
        aofh_is_now = aofh_is_now.sort{|a,b|
          key.reduce(0){|result, k| result != 0 ? result : (a[k] <=> b[k])}
        }
        aofh_should = aofh_should.sort{|a,b|
          key.reduce(0){|result, k| result != 0 ? result : (a[k] <=> b[k])}
        }
      end

      return (aofh_is_now == aofh_should)
    when :array_element
      aofh_should.each do |h|
        begin
          match = aofh_is_now.find_all{|x| x[key] == h[key]}
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

  def puppet_properties_for_type type = self.class.type
    # for 'type' accept any of
    # -- string, assumed to be unqualified VIM class name
    # -- symbol, assumed to be unqualified VIM class name
    # -- class object
    type = preferred_class_by_class(type) unless
        Class == type # TODO figure out if this should be "Class === type"

    # now get annotations for [preferred] type
    ppft = puppet_annotations[type]
    ppft[:type] = type
    ppft
  end

  def vim_class_by_name name
    # cache holds both hits (class) and misses (nil)
    @vim_classes_by_name ||=
      Hash.new do |hash, key|
        value = VIM.const_get key
        hash[key] = value
        value
      end
    @vim_classes_by_name[name.to_s.to_sym]
  end

  def preferred_class_by_class type
    # set class to use if there's a preferred subclass (for example,
    # VIM::VMwareDVSConfigSpec for VIM::DVSConfigSpec)
    @preferred_classes_by_class ||=
      begin
        Hash.
          new{|hash, key| key}.
          merge(
            VIM::DVSConfigSpec => VIM::VMwareDVSConfigSpec,
            VIM::DVPortSetting => VIM::VMwareDVSPortSetting,
            VIM::DistributedVirtualSwitchHostMemberBacking =>
              VIM::DistributedVirtualSwitchHostMemberPnicBacking
          )
      end
    type = vim_class_by_name(type) unless Class === type
    @preferred_classes_by_class[type]
  end

  def puppet_annotations
    @puppet_annotations ||=
      begin
        default = {
          :tags => Set.new,
        }
        Hash.
          new{|hash, key| default}.
          merge(

            VIM::DistributedVirtualSwitchHostMemberPnicSpec => {
              :tags => Set.new([MO_KEY]),
              :mo_key => [
                {
                  :property => 'uplinkPortgroupKey',
                  :type => VIM::DistributedVirtualPortgroup,
                  :scope => :dvswitch,
                },
=begin unimplemented
                {
                  :property => 'uplinkPortKey',
                  :type => VIM::DistributedVirtualPort,
                  :scope => :dvswitch,
                },
=end
              ],
            },

=begin unimplemented
            VIM::NumericRange => {
              :tags => Set.new([::Array]),
              :array_props => {
                :array_matching => :all,
                :comparison_scope => :array,
                :sort_array => true,
                :key => [
                  :start,
                  :end,
                ],
              },
            },
=end

            VIM::VmwareDistributedVirtualSwitchVlanSpec => {
              :tags => Set.new([ABSTRACT_CLASS]),
              :concrete_classes => Set.new([
                 VIM::VmwareDistributedVirtualSwitchPvlanSpec,
                 VIM::VmwareDistributedVirtualSwitchTrunkVlanSpec,
                 VIM::VmwareDistributedVirtualSwitchVlanIdSpec,
              ]),
            },

            nil => nil # just because the list cannot end with a comma
          )
      end
  end
end
