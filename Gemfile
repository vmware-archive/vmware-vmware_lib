source 'https://rubygems.org'

gem 'hashdiff'
gem 'rbvmomi'
gem 'net-ssh'
gem 'net-scp'

group :development, :test do
  gem 'rake'
  gem 'rspec', "~> 2.99", :require => false
  gem 'puppetlabs_spec_helper', '0.4.1', :require => false
  gem 'puppet-lint', :require => false
  gem 'rspec-puppet', :require => false
  # gem 'pry', :require => true
end

facterversion = ENV['GEM_FACTER_VERSION']
if facterversion
    gem 'facter', facterversion
else
    gem 'facter', :require => false
end

ENV['GEM_PUPPET_VERSION'] ||= ENV['PUPPET_GEM_VERSION']
if puppetversion = ENV['GEM_PUPPET_VERSION']
  gem 'puppet', puppetversion
else
  gem 'puppet', :require => false
end
