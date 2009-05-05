require 'rubygems'
require 'eventmachine'

require 'communicator'

class TestComm < Communicator
  def start
    shoot(0)      { |r| print "shoot(0) "; puts( r.success? ? "Ok" : "Fail #{r.inspect}") }
    speed(0, 0.5) { |r| print "speed(0, 0.5) "; puts( r.success? ? "Ok" : "Fail #{r.inspect}") }
    speed(0, 0)   { |r| print "speed(0, 0) "; puts( r.success? ? "Ok" : "Fail #{r.inspect}") }
    shoot(0)
    obstacles do |r|
      puts "Obstacles:"
      r.obstacles.each do |o|
        p o
      end
    end
    
    bases do |r|
      puts "Bases:"
      r.bases.each do |b|
        p b
      end
    end
    
    angvel(0, 0.1)
    puts "Done first messages"
  end
  
  def on_shoot(r)
    if r.success?
      puts "Successfully lobbed"
    else
      puts "Unable to shoot"
    end
  end
end

EventMachine.run do
  comm = EventMachine::connect('127.0.0.1', 5000, TestComm)
  timer = EventMachine::PeriodicTimer.new(5) do
     puts "the time is #{Time.now}. Last message: #{comm.last_msg}"
   end
end
