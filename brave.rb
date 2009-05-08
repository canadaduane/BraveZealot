require 'rubygems'
require 'eventmachine'

def bzrequire(relative_feature)
  require File.expand_path(File.join(File.dirname(__FILE__), relative_feature))
end

bzrequire 'lib/headquarters'

EventMachine.run do
  comm  = EventMachine::connect('127.0.0.1', 5000, BraveZealot::Headquarters)
  timer = EventMachine::PeriodicTimer.new(0.01){ comm.timer(0.01) }
  
  # timer = EventMachine::PeriodicTimer.new(5) do
  #    puts "#{Time.now} -- Last message: #{comm.last_msg}"
  # end
end
