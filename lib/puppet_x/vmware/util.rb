# Copyright (C) 2013 VMware, Inc.

# Allows usage of require_relative
unless Kernel.respond_to?(:require_relative)
  module Kernel
    def require_relative(path)
      require File.join(File.dirname(caller[0]), path.to_str)
    end
  end
end

module PuppetX
  module VMware
    module Util

      def self.camelize(snake_case, first_letter = :upper)
        EXCEPTIONS_CAMELIZE[snake_case] ||
        case first_letter
        when :upper
          snake_case.to_s.
            gsub(/\/(.?)/){ "::" + $1.upcase }.
            gsub(/(^|_)(.)/){ $2.upcase }
        when :lower
          snake_case.to_s[0].chr + camelize(snake_case)[1..-1]
        end
      end

      def self.snakeize(camel_case)
        EXCEPTIONS_SNAKEIZE[camel_case] ||
        camel_case.to_s.
          sub(/^[A-Z]+/){|s| s.downcase}.
          gsub(/[A-Z]+/){|s| '_' + s.downcase}
      end

=begin
        As of 2013/02/21, this file may be loaded twice,
        which creates confusing warning messages regarding
        constant redefinition.  To avoid these messages,
        self.const_missing has been added here.

        When proper handling of 'require'd files is available,
        ordinary definitions of the constants will be sufficient, 
        such as these, place at the top of the module:

        EXCEPTIONS_SNAKEIZE = {
          -- entries here --
        }.freeze

        EXCEPTIONS_CAMELIZE = EXCEPTIONS_SNAKEIZE.invert.freeze
=end
      def self.const_missing name
        case name
        when :EXCEPTIONS_SNAKEIZE
          # EXCEPTIONS_SNAKEIZE is defined explicitly by this hash table
          val = {
            'VMwareDVSConfigSpecMap' => 'vmware_dvs_config_spec_map',
          }.freeze
        when :EXCEPTIONS_CAMELIZE
          # EXCEPTIONS_CAMELIZE is the inverse of EXCEPTIONS_SNAKEIZE
          val = const_get(:EXCEPTIONS_SNAKEIZE).invert.freeze
        else
          raise NameError, "Uninitialized constant: #{self.name}::#{name}"
        end
        const_set(name, val)
      end

      def self.nested_value(hash, keys, default=nil)
        value = hash.dup
        keys.each_with_index do |item, index|
          # handle Hash or RbVmomi::BasicTypes::ObjectWithProperties
          #
          # ASSUMPTION: [] returns nil for missing key
          #             for everything we are interested in
          #
          unless (value.respond_to? :[]) && (not value[item].nil?)
            default = yield hash, keys, index if block_given?
            return default
          end
          value = value[item]
        end
        value
      end

      def self.nested_value_set(hash, keys, value, keys_are_syms=true)
        fail "'hash' is not a hash: '#{hash.inspect}'" unless hash.is_a? Hash
        fail "'keys' is not an array: '#{keys.inspect}'" unless keys.is_a? Array
        fail "'keys' array is empty" if keys.empty?

        node = hash
        if keys_are_syms
          keys = keys.dup.map{|el| el.to_sym}
        else
          keys = keys.dup.map{|el| el.to_s}
        end
        Puppet.debug "setting value at #{keys.inspect}"

        # Note: if keys has only one element, keys[0..-2] is [],
        # so this code will insert value at top level of hash...
        # not particularly useful, but not obviously an error

        keys[0..-2].each_with_index do |key, index|
          if not node.include? key
            Puppet.debug "adding empty hash at #{keys[0..index].inspect}"
            node = node[key] = {}
          elsif node[key].is_a? Hash
            node = node[key]
          else
            Puppet.debug "node is not a hash: '#{node[key].inspect}'"
            fail "node at #{keys[0..index].inspect} is not a hash"
          end
        end

        node[keys[-1]] = value
      end

      def self.string_keys(myhash)
        myhash.keys.each do |key|
          value = myhash.delete(key)
          if value.is_a? Hash
            value = string_keys(value)
          end

          myhash[(key.to_s rescue key) || key] = value
        end
        myhash
      end

      def self.symbolize_keys(myhash)
        myhash.keys.each do |key|
          value = myhash.delete(key)
          if value.is_a? Hash
            value = symbolize_keys(value)
          end

          myhash[(key.to_sym rescue key) || key] = value
        end
        myhash
      end

    end
  end
end
