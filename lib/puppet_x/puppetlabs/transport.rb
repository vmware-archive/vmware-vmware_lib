# Monkey patch transaction to cleanup Transport connection.
# We need this to cleanup ssh/vcenter/vshield connections regardless of resource apply result.
module Puppet
  class Transaction
    alias_method :evaluate_original, :evaluate

    def evaluate
      evaluate_original
      PuppetX::Puppetlabs::Transport.cleanup
    end
  end
end

module PuppetX
  module Puppetlabs
    module Transport
      @@instances = []

      # Accepts a puppet resource reference, resource catalog, and loads connetivity info.
      def self.retrieve(options={})
        unless res_hash = options[:resource_hash]
          catalog = options[:catalog]
          res_ref = options[:resource_ref].to_s
          name = Puppet::Resource.new(nil, res_ref).title
          res_hash = catalog.resource(res_ref).to_hash
        end

        provider = options[:provider]

        unless transport = find(name, provider)
          transport = PuppetX::Puppetlabs::Transport::const_get(provider.capitalize).new(res_hash)
          transport.connect
          @@instances << transport
        end

        transport
      end

      def self.cleanup
        @@instances.each do |i|
          i.close if i.respond_to? :close
        end
      rescue
      end

      private

      def self.find(name, provider)
        @@instances.find{ |x| x.is_a? PuppetX::Puppetlabs::Transport::const_get(provider.capitalize) and x.name == name }
      end
    end
  end
end
