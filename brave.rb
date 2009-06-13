#!/usr/bin/env ruby

require 'ostruct'
require 'optparse'
require 'yaml'

# Use reasonable defaults and parse shell args for specific options

def state_list(list = "dummy")
  # Repeat for default of up to 10 agents
  list.split(',').map{ |j| j.strip.to_sym } * 10
end

config_file = "config.yml"

if File.exist?(config_file)
  $options = OpenStruct.new(YAML.load(IO.read(config_file)).merge(:config_file => "config.yml"))
else
  $options = OpenStruct.new(:config_file => "config.yml")
end

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

  opts.on("-c", "--config-file [FILE]", "The Yaml configuration file") do |c|
    $options.config_file = c
  end

  opts.on("-i", "--initial-state [LIST,OF,STATES]", "(e.g. 'dummy', 'smart')") do |i|
    $options.initial_state = i
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

puts "Starting brave.rb with the following options: \n"
y $options.instance_variable_get("@table")

$options.initial_state = state_list($options.initial_state)

# Our main program begins here:

require 'rubygems'
require 'eventmachine'
require(File.join(File.dirname(__FILE__), "bzrequire"))
bzrequire 'lib/headquarters'
bzrequire 'lib/astar/astar',
  "You may need to compile the astar (A*) extension: \n" +
  "$ cd lib/astar && ruby extconf.rb && make\n"

puts

# Check that the bzfs server is running on the expected port
if `netstat -an|grep \.#{$options.port}\s`.empty?
  puts "Warning: unable to connect to port #{$options.port}"
end

EventMachine.run do
  EventMachine::connect(
    $options.server,
    $options.port,
    BraveZealot::Headquarters)
end
