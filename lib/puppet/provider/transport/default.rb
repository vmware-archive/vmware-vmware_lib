Puppet::Type.type(:transport).provide(:default) do

  defaultfor :default_provider => 'true'

  desc 'Basic provider for transport that just returns the value passed into the resource'
 
  def username
    resource[:username]
  end

  def password
    resource[:password]
  end

  def server
    resource[:server]
  end

  def options
    resource[:options]
  end

  def self.post_resource_eval
    PuppetX::Puppetlabs::Transport.cleanup
  end

end
