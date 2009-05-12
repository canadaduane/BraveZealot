require 'rubygems'
require 'eventmachine'

bzrequire 'lib/coord'
bzrequire 'lib/team'
bzrequire 'lib/obstacle'
bzrequire 'lib/base'
bzrequire 'lib/flag'
bzrequire 'lib/shot'
bzrequire 'lib/my_tank'
bzrequire 'lib/other_tank'
bzrequire 'lib/constant'

module BraveZealot
  class Communicator < EventMachine::Protocols::LineAndTextProtocol
    attr_reader :last_msg
    attr_reader :message_queue
    
    # Contains the response for a given command.  The +value+
    # can be a boolean or any of the Structs defined above.
    class Response
      attr_accessor :value
      attr_accessor :time, :command, :index, :args
    
      def initialize(time, command, index, args)
        @time, @command, @index, @args = time.to_f, command, index.to_i, args
        @value = nil
        @complete = false
      end
    
      def complete!
        @complete = true
      end
    
      def complete?
        @complete
      end
    
      def success?
        @value == true
      end
    
      def array?
        @value.is_a? Array
      end
    
      def expect_array_of!(klass)
        if array? and (@value.empty? or @value.first.is_a?(klass))
          return
        else
          raise TypeError, "expecting [#{klass}]"
        end
      end
    
      # Use a little type checking when we access expected response objects.
      # For example, if we ask for response.obstacles but @value contains a
      # list of Team objects, we should raise a TypeError.
      { :teams      => Team,
        :obstacles  => Obstacle,
        :bases      => Base,
        :flags      => Flag,
        :shots      => Shot,
        :mytanks    => MyTank,
        :othertanks => OtherTank,
        :constants  => Constant }.
      each do |method, klass|
        define_method(method) do
          expect_array_of! klass
          @value
        end
      end
    
      def add(item)
        @value ||= []
        @value << item
      end
    end
  
    def initialize
      @message_queue = []
      super
    end
  
    def start
      puts "communicator started (you should subclass this)"
    end
  
    { :shoot      => ["index"],
      :speed      => ["index", "speed"],
      :angvel     => ["index", "angvel"],
      :accelx     => ["index", "accel"],
      :accely     => ["index", "accel"],
      :teams      => [],
      :obstacles  => [],
      :bases      => [],
      :flags      => [],
      :shots      => [],
      :mytanks    => [],
      :othertanks => [],
      :constants  => [] }.
    each do |method, args|
      # Create each of the above methods as verbs in our tank vocabularly.
      # Each method expects the arguments specified in the array above, and
      # an optional reaction block.
      define_method(method) do |*ss, &reaction|
        unless ss.size == args.size
          raise ArgumentError,
            "Expects #{args.empty? ? 'nothing' : args.inspect} as args"
        end
        words = ([method] + ss).map{ |w| w.to_s }
        say words.join(" ")
        @message_queue << reaction
      end
    end
  
    def unbind
      # If the agent is disconnected, shut down
      puts "Agent disconnected (possibly caused by a Ruby exception?)"
      EventMachine::stop_event_loop
    end
  
    protected
    def receive_line(line)
      puts "RECV: #{line}"
      @last_msg = line
    
      case line
      when /^bzrobots [\d\.]+$/ then
        say "agent 1"
        start
      when /^ack ([\d\.]+)( \w+)?( \d+)?(.*)$/ then
        time, cmd, index, args = $1, $2, $3, $4
        time  &&= time.strip
        cmd   &&= cmd.strip
        index &&= index.strip
        args  &&= args.strip.scan(/([^\s]+)+/).flatten
        @response = Response.new(time, cmd, index, args)
      when /^error(.*)$/ then
        # Ignore errors for now
      when /^begin\s*$/ then
        @response.value = []
      when /^(ok|fail)(.*)$/ then
        @response.value = ($1 == "ok" ? true : false)
        @response.complete!
      when /^team (\w+) (\d+)$/ then
        @response.add Team.new($1, $2.to_i)
      when /^obstacle (.*)$/ then
        coords = $1.scan(/[\d\.\-\+]+/).enum_slice(2).map{ |x, y| Coord.new(x, y) }
        @response.add Obstacle.new(coords)
      when /^base (\w+) (.*)$/ then
        color = $1
        coords = $2.scan(/[\d\.\-\+]+/).enum_slice(2).map{ |x, y| Coord.new(x, y) }
        @response.add Base.new(color, coords)
      when /^flag (\w+) (\w+) ([\d\.\-\+]+) ([\d\.\-\+]+)$/ then
        @response.add Flag.new($1, $2, $3.to_f, $4.to_f)
      when /^shot ([\d\.\-\+]+) ([\d\.\-\+]+) ([\d\.\-\+]+) ([\d\.\-\+]+)$/ then
        @response.add Shot.new($1.to_f, $2.to_f, $3.to_f, $4.to_f)
      when /^mytank (\d+) (\w+) (alive|dead|\w+) (\d+) ([\d\.\-\+]+) ([\-\w]+) ([\d\.\-\+]+) ([\d\.\-\+]+) ([\d\.\-\+]+) ([\d\.\-\+]+) ([\d\.\-\+]+) ([\d\.\-\+]+)$/ then
        @response.add \
          MyTank.new($1.to_i, $2, $3, $4.to_i, $5.to_f, $6, $7.to_f,
                     $8.to_f, $9.to_f, $10.to_f, $11.to_f, $12.to_f)
      when /^othertank (\w+) (\w+) (alive|dead|\w+) ([\-\w]+) ([\d\.\-\+]+) ([\d\.\-\+]+) ([\d\.\-\+]+)$/ then
        @response.add \
          OtherTank.new($1, $2, $3, $4, $5.to_f, $6.to_f, $7.to_f)
      when /^constant (\w+) (.+)$/ then
        @response.add Constant.new($1, $2)
      when /^end\s*$/ then
        @response.complete!
      end
  
      if @response && @response.complete?
        # Call the catch-all global response method
        send("on_any", @response) if respond_to?("on_any")
        # Call the global response method for this kind of command
        cmd = "on_#{@response.command}"
        send(cmd, @response) if respond_to?(cmd)
        # Call the specific reaction to this particular command
        reaction = @message_queue.shift
        reaction.call(@response) if reaction
      end
    rescue Exception => e
      puts e
      puts e.backtrace.join("\n")
      raise e
    end
  
    def say(text)
      puts "SEND: #{text}"
      send_data(text.strip + "\n")
    end
  
  end
end