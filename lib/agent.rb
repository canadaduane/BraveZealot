bzrequire 'lib/communicator'

module BraveZealot
  module DummyStates
    # Shortcut state for :forward_until_hit
    def state_dummy
      @state = :dummy_forward
    end
    
    def state_dummy_forward
      curr_speed = Math.sqrt(@tank.vx**2 + @tank.vy**2)
      # Check if we've hit something
      @state =
        if curr_speed < 24.5
          speed(-0.1)
          :dummy_random_turn
        else
          :dummy_forward
        end
    end
    
    def state_dummy_random_turn
      angvel(rand < 0.5 ? -1.0 : 1.0) do
        sleep(2.0) do
          speed 1.0
          angvel(0.0)
          @state = :dummy_accel_once
        end
      end
    end
    
    def state_dummy_accel_once
      @state = :wait
      sleep(1.5) { @state = :dummy_forward }
    end
  end
  
  module SmartStates
    def state_smart
      if @goal
        path = hq.map.search(@tank, @goal)
        puts "Path: #{path.inspect}"
        # move = @goal.suggest_move(@tank.x, @tank.y, angle)
        # speed move.speed
        # angvel move.angvel
      else
        @state = :smart_return_home
      end
    end
    
    def state_smart_return_home
      @goal = hq.my_base.center
      @state = :smart
    end
  end

  class Agent
    # hq   :: Headquarters  -> The headquarters object
    # tank :: Tank          -> Data object
    attr_accessor :hq, :tank, :mode

    # state :: Symbol  -> :capture_flag, :home
    # goal :: Coord   -> Coordinate indicating where the agent is headed
    attr_accessor :state, :goal
    
    include DummyStates
    include SmartStates
    
    # See above for definitions of hq and tank
    def initialize(hq, tank, initial_state = nil)
      @hq, @tank = hq, tank
      @state = initial_state || :dummy
      @goal = nil
      puts "Starting agent #{@tank.index}: #{@state}"
      start
    end
    
    def start
      EventMachine::PeriodicTimer.new($options.refresh) do
        refresh($options.refresh) do
          send("state_#{@state}")
        end
      end
    end
    
    def state_wait
      # do nothing
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
        @hq.send(m, @tank.index, *args, &block)
      else
        puts "Failed to find #{m}"
        raise NameError
      end
    end
  end
  
end
