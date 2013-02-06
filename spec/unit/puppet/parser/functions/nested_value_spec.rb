#!/usr/bin/env rspec

require 'spec_helper'

describe "the nested_value function" do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  it "should exist" do
    Puppet::Parser::Functions.function("nested_value").should == "function_nested_value"
  end

  it "should raise a ParseError if there is not exactly 2 arguments" do
    lambda { scope.function_nested_value([1]) }.should( raise_error(Puppet::ParseError))
    lambda { scope.function_nested_value([1, 2, 3]) }.should( raise_error(Puppet::ParseError))
  end

  it "should raise a ParseError if second argument is not an Array" do
    lambda { scope.function_nested_value([{}, 1]) }.should( raise_error(Puppet::ParseError))
  end

  it "should return :undef for a unavailable hash key" do
    result = scope.function_nested_value([{}, ['a', 'b']])
    result.should(eq(:undef))
  end

  it "should return correct value when available" do
    result = scope.function_nested_value([{'a'=>{'b'=>3}}, ['a','b']])
    result.should(eq(3))
  end
end
