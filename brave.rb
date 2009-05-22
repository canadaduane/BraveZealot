require 'ostruct'
require 'optparse'

# Use reasonable defaults and parse shell args for specific options

$options = OpenStruct.new(
  :server        => '127.0.0.1',
  :port          => 3002,
  :initial_state => ['dummy'] * 10,
  :refresh       => 0.1,
  :gnuplot_file  => 'search.gpi', 
  :debug         => false
) 

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

  opts.on("-i", "--initial-state [LIST,OF,STATES]", "(e.g. 'dummy', 'smart')") do |i|
    $options.initial_state = i.split(',').map{ |j| j.strip.to_sym } * 10 # repeat for default of up to 10 agents
  end

  opts.on("-r", "--refresh [VALUE]", "Potential field refresh rate (e.g. 0.05)") do |r|
    $options.refresh = r.to_f
  end

  opts.on("-g", "--gnuplot [VALUE]", "Where should we export the gnuplot file?") do |r|
    $options.gnuplot_file = r
  end

  opts.on("-d", "--debug", "Do you want to see the detailed gnuplot?") do |r|
    $options.debug = true
  end
end

opts.parse!(ARGV)


# Our main program begins here:

require 'rubygems'
require 'eventmachine'
require(File.join(File.dirname(__FILE__), "bzrequire"))
bzrequire 'lib/headquarters'
bzrequire 'lib/astar/astar',
  "You may need to compile the astar (A*) extension: \n" +
  "$ cd lib/astar && ruby extconf.rb && make\n"

EventMachine.run do
  EventMachine::connect(
    $options.server,
    $options.port,
    BraveZealot::Headquarters)
end
