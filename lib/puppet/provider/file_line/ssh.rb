require 'pathname'
mod = Puppet::Module.find('vmware_lib', Puppet[:environment].to_s).path rescue Pathname.new(__FILE__).parent.parent.parent.parent.parent
require File.join mod, 'lib/puppet/type/transport'
require File.join mod, 'lib/puppet_x/puppetlabs/transport'
require File.join mod, 'lib/puppet_x/puppetlabs/transport/ssh'

Puppet::Type.type(:file_line).provide(:ssh) do
  confine :feature => :ssh

  include PuppetX::Puppetlabs::Transport

  def exists?
    lines.find do |line|
      line.chomp == resource[:line].chomp
    end
  end

  def create
    if resource[:match]
      handle_create_with_match
    elsif resource[:after]
      handle_create_with_after
    else
      append_line
    end
  end

  private
  def lines
    @lines ||= transport.exec!("cat #{resource[:path]}").split("\n")
  end

  def handle_create_with_match()
    regex = resource[:match] ? Regexp.new(resource[:match]) : nil
    match_count = lines.select { |l| regex.match(l) }.size
    if match_count > 1 && resource[:multiple].to_s != 'true'
      raise Puppet::Error, "More than one line in file '#{resource[:path]}' matches pattern '#{resource[:match]}'"
    elsif match_count == 1
      Puppet.debug('Replacing config line')
      transport.exec!("sed -i 's|#{resource[:match]}.*|#{resource[:line]}|' #{resource[:path]}")
    else
      append_line
    end
  end

  def handle_create_with_after
    regex = Regexp.new(resource[:after])

    count = lines.count {|l| l.match(regex)}

    case count
    when 1 # find the line to put our line after
      # append in middle
      Puppet.debug("Appending config line after #{resource[:after]}")
      transport.exec!("sed -i \"/#resource[:after]/a#{resource[:line]}\" #{resource[:path]}")
    when 0 # append the line to the end of the file
      # append at the end
      append_line
    else
      raise Puppet::Error, "#{count} lines match pattern '#{resource[:after]}' in file '#{resource[:path]}'.  One or no line must match the pattern."
    end
  end

  def append_line
    Puppet.debug('Appending config line at the end')
    transport.exec!("sed -i \"$ a#{resource[:line]}\" #{resource[:path]}")
  end
end
