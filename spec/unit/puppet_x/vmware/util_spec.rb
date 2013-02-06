#!/usr/bin/env rspec

require 'spec_helper'

describe PuppetX::VMware::Util do
  it 'should camelize snake_case with capital default' do
    PuppetX::VMware::Util.camelize('snake_case').should == 'SnakeCase'
  end

  it 'should camelize snake_case with appropriate capitalization' do
    PuppetX::VMware::Util.camelize('snake_case', :lower).should == 'snakeCase'
  end

  it 'should snakeize CamelCase' do
    PuppetX::VMware::Util.snakeize('CamelCase').should == 'camel_case'
  end

  it 'should default nil for missing nested value' do
    PuppetX::VMware::Util.nested_value({'a'=>{'b'=>1}}, ['a', 'c']).should be_nil
  end

  it 'should accept block for missing nested value' do
    PuppetX::VMware::Util.nested_value({'a'=>{'b'=>1}}, ['a', 'c']){2}.should == 2
  end

  it 'should retrieve nested value' do
    PuppetX::VMware::Util.nested_value({'a'=>{'b'=>1}}, ['a', 'b']).should == 1
  end

  # TODO: nested_value_set
end
