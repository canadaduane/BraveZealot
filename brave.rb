require 'rubygems'
require 'eventmachine'
require 'ostruct'
require 'optparse'

def bzrequire(relative_feature)
  require File.expand_path(File.join(File.dirname(__FILE__), relative_feature))
end

$options = OpenStruct.new(:server => '127.0.0.1', :port => 5000, :brain => 'smart')

opts = OptionParser.new do |opts|
  opts.banner = "Usage: brave.rb [options]"

  opts.separator ""
  opts.separator "Specific options:"

  opts.on("-s", "--server [SERVER]", "Connect to server") do |srv|
    $options.server = srv
  end

  opts.on("-p", "--port [NUMBER]", "Connect to port") do |port|
    $options.port = port.to_i
  end

  opts.on("-b", "--brain [NAME]", "(e.g. 'dummy', 'smart')") do |brain|
    $options.brain = brain
  end
end

opts.parse!(ARGV)

bzrequire 'lib/headquarters'

EventMachine.run do
  EventMachine::connect(
    $options.server,
    $options.port,
    BraveZealot::Headquarters)
end
