require 'rubygems'
require 'eventmachine'

class Agent < EventMachine::Connection
  def initialize
    super
  end
  
  def receive_data(data)
    puts "RECEIVED: #{data}"
  end
  
  def unbind
    # If the agent is disconnected, shut down
    EventMachine::stop_event_loop
  end
end

EM.run do
  EventMachine::connect '127.0.0.1', 5154, Agent
end
