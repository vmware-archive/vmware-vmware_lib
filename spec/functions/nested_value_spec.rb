#!/usr/bin/env rspec
# Copyright (C) 2013 VMware, Inc.

require 'spec_helper'

describe "nested_value" do

  it "should exist" do
    is_expected.not_to eq(nil)
  end

  it "should raise a ParseError if there is not exactly 2 arguments" do
    is_expected.to run.with_params(1).and_raise_error(Puppet::ParseError, /nested_value\(\): Wrong number of arguments/) 
    is_expected.to run.with_params(1, 2, 3).and_raise_error(Puppet::ParseError, /nested_value\(\): Wrong number of arguments/)
  end

  it "should raise a ParseError if second argument is not an Array" do
    is_expected.to run.with_params({}, 1).and_raise_error(Puppet::ParseError, /keys should be an array/)
  end

  it "should return :undef for a unavailable hash key" do
    is_expected.to run.with_params({}, ['a','b']).and_return(:undef)
  end

  it "should return correct value when available" do
    is_expected.to run.with_params({'a'=>{'b'=>3}}, ['a','b']).and_return(3)
  end
end
