require 'rubygems'
require 'eventmachine'

require 'generic_agent'

class Agent < GenericAgent
  def start
    shoot(0) { |r, succ| puts "Ok 1" if succ }
    speed(0, 0.5) { |r, succ| puts "Speed 0.5" if succ }
    speed(0, 0) { |r, succ| puts "Speed 0" if succ }
    shoot(0)
    obstacles do |r, obs|
      obs.each do |o|
        p o
      end
    end
    
    angvel(0, 0.1)
    puts "Done first messages"
  end
  
  def on_shoot(response, success)
    if success
      puts "Successfully lobbed"
    else
      puts "Unable to shoot"
    end
  end
end

EventMachine.run do
  agent = EventMachine::connect('127.0.0.1', 5000, Agent)
  timer = EventMachine::PeriodicTimer.new(5) do
     puts "the time is #{Time.now}. Agent's last message: #{agent.last_msg}"
   end
end
