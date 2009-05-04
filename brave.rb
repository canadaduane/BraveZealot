require 'rubygems'
require 'eventmachine'

class Agent < EventMachine::Protocols::LineAndTextProtocol
  attr_reader :last_msg
  
  class Failure < Exception; end
  
  Team      = Struct.new(:color, :players)
  Obstacle  = Struct.new(:x1, :y1, :x2, :y2)
  Base      = Struct.new(:color, :x1, :y1, :x2, :y2)
  Flag      = Struct.new(:color, :possession, :x, :y)
  Shot      = Struct.new(:x, :y, :vx, :vy)
  MyTank    = Struct.new(:index, :callsign, :status, :shots_available, :time_to_reload, :flag, :x, :y, :angle, :vx, :vy, :angvel)
  OtherTank = Struct.new(:callsign, :color, :status, :flag, :x, :y, :angle)
  Constant  = Struct.new(:name, :value)
  
  # Contains the response for a given command.  The +value+ can be a boolean, a float, or any of the Structs defined above.
  class Response
    attr_accessor :value
    attr_accessor :time, :command, :index, :args
    
    def initialize(time, command, index, args)
      @time, @command, @index, @args = time, command, index, args
      @value = nil
      @complete = false
    end
    
    def complete!
      @complete = true
    end
    
    def complete?
      @complete
    end
    
    def add(item)
      @value ||= []
      @value << item
    end
  end
  
  def initialize
    super
  end
  
  protected
  def receive_data(data)
    puts "RECV: #{data}"
    @last_msg = data
    
    case data.strip
    when /^bzrobots [\d\.]+$/:
      say "agent 1"
      # say "angvel 0 0.1"
      say "speed 0 0"
      # say "shoot 0 0"
      # say "speed 0 0"
    when /^ack ([\d\.]+) (\w+) (\d+)(.*)$/
      time, cmd, index, args = $1, $2, $3, ($4.strip.scan(/([^\s]+)+/).flatten)
      @response = Response.new(time, cmd, index, args)
    when /^error(.*)$/
      # Ignore errors for now
    when /^begin\s*$/
      # Ignore
    when /^(ok|fail)(.*)$/
      @response.value = ($1 == "ok" ? true : false)
      @response.complete!
    when /^team (\w+) (\d+)$/
      @response.add Team.new($1, $2.to_i)
    when /^obstacle ([\d\.\-\+]+) ([\d\.\-\+]+) ([\d\.\-\+]+) ([\d\.\-\+]+)$/
      @response.add Obstacle.new($1.to_f, $2.to_f, $3.to_f, $4.to_f)
    when /^base (\w+) ([\d\.\-\+]+) ([\d\.\-\+]+) ([\d\.\-\+]+) ([\d\.\-\+]+)$/
      @response.add Base.new($1, $2.to_f, $3.to_f, $4.to_f, $5.to_f)
    when /^flag (\w+) (\w+) ([\d\.\-\+]+) ([\d\.\-\+]+)$/
      @response.add Flag.new($1, $2, $3.to_f, $4.to_f)
    when /^shot ([\d\.\-\+]+) ([\d\.\-\+]+) ([\d\.\-\+]+) ([\d\.\-\+]+)$/
      @response.add Shot.new($1.to_f, $2.to_f, $3.to_f, $4.to_f)
    when /^mytank (\d+) (\w+) (alive|dead|\w+) (\d+) ([\d\.\-\+]+) ([\-\w]+) ([\d\.\-\+]+) ([\d\.\-\+]+) ([\d\.\-\+]+) ([\d\.\-\+]+) ([\d\.\-\+]+) ([\d\.\-\+]+)$/
      @response.add MyTank.new($1.to_i, $2, $3, $4.to_i, $5.to_f, $6, $7.to_f, $8.to_f, $9.to_f, $10.to_f, $11.to_f, $12.to_f)
    when /^othertank (\w+) (\w+) (alive|dead|\w+) ([\-\w]+) ([\d\.\-\+]+) ([\d\.\-\+]+) ([\d\.\-\+]+)$/
      @response.add OtherTank.new($1, $2, $3, $4, $5.to_f, $6.to_f, $7.to_f)
    when /^end\s*$/
      @response.complete!
    end
    
    if @response && @response.complete?
      send("on_#{@response.command}", @response, @response.value)
    end
  end
  
  def say(text)
    puts "SEND: #{text}"
    send_data(text.strip + "\n")
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
  
  def unbind
    # If the agent is disconnected, shut down
    EventMachine::stop_event_loop
  end
end

EventMachine.run do
  agent = EventMachine::connect('127.0.0.1', 5000, Agent)
  timer = EventMachine::PeriodicTimer.new(5) do
     puts "the time is #{Time.now}. Agent's last message: #{agent.last_msg}"
   end
end
