# Copyright (C) 2013 VMware, Inc.
module Puppet::Parser::Functions

  # Public: Fetches value from a nested hash or return :undef for missing keys.
  #
  # Examples:
  #
  #   nested_value({'a' => {'b' => 1 }}, ['a', 'b'])
  #   # => 1
  #   nested_value({'a' => {'b' => 1 }}, ['a', 'c'])
  #   # => :undef
  #
  # Returns nested hash key value.
  newfunction(:nested_value, :type => :rvalue, :doc => <<-EOS
    EOS
  ) do |arguments|

    raise(Puppet::ParseError, "nested_value(): Wrong number of arguments " +
      "given (#{arguments.size} for 2)") if arguments.size != 2

    value = arguments[0]
    keys = arguments[1]

    raise(Puppet::ParseError, "keys should be an array.") unless keys.is_a? Array
    keys.each_with_index do |item, index|
      unless (value.is_a? Hash) && (value.include? item)
        value = :undef
        break
      end
      value = value[item]
    end
    return value
  end
end
