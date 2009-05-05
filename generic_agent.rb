require 'rubygems'
require 'eventmachine'

class GenericAgent < EventMachine::Protocols::LineAndTextProtocol
  attr_accessor :debug
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
      @debug = false
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
  
  def first_message
  end
  
  protected
  def receive_data(data)
    puts "RECV: #{data}" if @debug
    @last_msg = data
    
    for line in data.strip.lines
      case line
      when /^bzrobots [\d\.]+$/:
        say "agent 1"
        first_message
      when /^ack ([\d\.]+)( \w+)?( \d+)?(.*)$/
        time, cmd, index, args = $1, $2, $3, $4
        time  &&= time.strip
        cmd   &&= cmd.strip
        index &&= index.strip
        args  &&= args.strip.scan(/([^\s]+)+/).flatten
        # puts "time: #{time.inspect}, cmd: #{cmd.inspect}, index: #{index.inspect}, args: #{args.inspect}"
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
  end
  
  def say(text)
    puts "SEND: #{text}" if @debug
    send_data(text.strip + "\n")
  end
  
  def unbind
    # If the agent is disconnected, shut down
    EventMachine::stop_event_loop
  end
end
