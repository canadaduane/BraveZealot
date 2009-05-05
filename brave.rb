require 'rubygems'
require 'eventmachine'

require 'generic_agent'

class Agent < GenericAgent
  def first_message
    say "teams"
    say "angvel 0 0.1"
    say "shoot 0"
    say "speed 0 0.4"
  end
  
  def on_shoot(response, success)
    if success
      puts "Successfully lobbed"
    else
      raise Failure, "unable to shoot"
    end
  end
  
  def on_speed(response, success)
    if success
      puts "Successfully changed speed"
    else
      raise Failure, "unable to change speed"
    end
  end

  def on_angvel(response, success)
    if success
      puts "Successfully changed angular velocity"
    else
      raise Failure, "unable to change angular velocity"
    end
  end
  
  def on_teams(response, teams)
    puts "Teams: #{teams.inspect}"
  end
end

EventMachine.run do
  agent = EventMachine::connect('127.0.0.1', 5000, Agent)
  timer = EventMachine::PeriodicTimer.new(5) do
     puts "the time is #{Time.now}. Agent's last message: #{agent.last_msg}"
   end
end
