require 'ostruct'
require 'optparse'

# Use reasonable defaults and parse shell args for specific options

$options = OpenStruct.new(
  :server  => '127.0.0.1',
  :port    => 6000,
  :brain   => 'smart',
  :refresh => 0.05)

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

  opts.on("-r", "--refresh [VALUE]", "Potential field refresh rate (e.g. 0.05)") do |r|
    $options.refresh = r.to_f
  end
end

opts.parse!(ARGV)


# Our main program begins here:

require 'rubygems'
require 'eventmachine'
require(File.join(File.dirname(__FILE__), "bzrequire"))
bzrequire 'lib/headquarters'

EventMachine.run do
  EventMachine::connect(
    $options.server,
    $options.port,
    BraveZealot::Headquarters)
end
