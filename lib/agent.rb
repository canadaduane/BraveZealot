bzrequire 'lib/communicator'
bzrequire 'lib/agent_states/dummy'
bzrequire 'lib/agent_states/seek'
bzrequire 'lib/agent_states/decoy'
bzrequire 'lib/agent_states/sniper'
bzrequire 'lib/agent_states/sitting_duck'
bzrequire 'lib/agent_states/constant_velocity'
bzrequire 'lib/agent_states/constant_acceleration'
bzrequire 'lib/agent_states/gaussian_acceleration'
bzrequire 'lib/agent_states/wild'
bzrequire 'lib/agent_states/hunting'
bzrequire 'lib/agent_states/random_search'
bzrequire 'lib/agent_states/defender'
bzrequire 'lib/agent_states/assassin'
require 'ruby-debug'

RADIANS_PER_DEGREE = Math::PI/180

class Array
  # If +number+ is greater than the size of the array, the method
  # will simply return the array itself sorted randomly
  def randomly_pick(number)
    sort_by{ rand }.slice(0...number)
  end
end

module BraveZealot
  class Agent
    # hq   :: Headquarters  -> The headquarters object
    # tank :: Tank          -> Data object
    attr_accessor :hq, :tank, :mode

    # state :: Symbol  -> :capture_flag, :home
    # goal :: Coord   -> Coordinate indicating where the agent is headed
    attr_accessor :state, :goal
    attr_accessor :group
    attr_accessor :path, :short_path
    attr_accessor :timers
    
    include DummyStates
    include SeekStates
    include DecoyStates
    include SniperStates
    include HuntingStates
    include RandomSearchStates
    # Conforming Pigeons
    include SittingDuckStates
    include ConstantVelocityStates
    include ConstantAccelerationStates
    include GaussianAccelerationStates
    # Non-conforming Pigeons
    include WildStates
    # Tourmanet passoff states
    include DefenderStates
    include AssassinStates
    
    # See above for definitions of hq and tank
    def initialize(hq, tank)
      @hq, @tank = hq, tank
      @goal = nil
      @timers = []
      # Satisfactory proximity of tank to its destination
      @proximity = 8
    end
    
    def funeral
      @state_loop.cancel
      cancel_timers
    end
    
    def begin_state_loop(initial_state = nil)
      @state = initial_state || :dummy
      puts "\nStarting agent #{@tank.index}: #{@state}"
      # Change state up to every +refresh+ seconds
      @state_loop = EventMachine::PeriodicTimer.new($options.refresh) do
        # puts "Agent #{@tank.index} entering state #{@state.inspect}"
        send(@state)
      end
    end
    
    # Add a timer and record it in this agent's list of timers
    def periodically(period = 0.5, maximum = nil, &block)
      @timers << hq.periodic_action(period, maximum, &block)
    end
    
    # Cancel all timers for this agent
    def cancel_timers
      @timers.each{ |t| t.cancel }
    end
    
    # Check if we have fresh enough data, otherwise execute the block
    def check(symbol, freshness, default, force_check)
      if ((Time.now - last_checked(symbol)) > freshness) or force_check then
        checked(symbol,Time.now)
        yield
      else
        default
      end
    end

    def last_checked(symbol)
      @times ||= {}
      @times[symbol] || Time.at(0)
    end

    def checked(symbol,time)
      @times ||= {}
      puts "Refreshing #{symbol}"
      @times[symbol] = time
    end
    
    def wait
      # do nothing
    end
    
    def push_next_state(state, next_state)
      @next_state ||= {}
      @next_state[state] ||= []
      @next_state[state].push next_state
    end
    
    def transition(state, default)
      @next_state ||= {}
      @next_state[state] ||= []
      @state = @next_state[state].shift || default
    end
    
    def set_state(state, options = {}, &abort)
      options[:abort] = abort unless abort.nil?
      # Set all appropriate instance variables
      options.each do |k, v|
        instance_variable_set("@#{k}", v)
      end
      cancel_timers
      @next_state = {}
      @state = state
    end
    
    def refresh(freshness, &block)
      @hq.refresh(:mytanks, freshness, &block)
    end
    
    def sleep(time, &block)
      EventMachine::Timer.new(time, &block)
    end
    
    # Forward certain messages to headquarters, with our tank index
    def method_missing(m, *args, &block)
      if Communicator::COMMANDS.keys.include?(m.to_sym)
        if m.to_sym == :shots then
          @hq.send(m, &block)
        else
          @hq.send(m, @tank.index, *args, &block)
        end
      else
        puts "Failed to find method '#{m}'"
        raise NameError
      end
    end
  end
  
end
