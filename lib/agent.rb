bzrequire 'lib/communicator'
require 'ruby-debug'

class Array
  # If +number+ is greater than the size of the array, the method
  # will simply return the array itself sorted randomly
  def randomly_pick(number)
    sort_by{ rand }.slice(0...number)
  end
end

module BraveZealot
  module DummyStates
    # Shortcut state for :forward_until_hit
    def dummy
      @state = :dummy_forward
    end
    
    def dummy_forward
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
    
    def dummy_random_turn
      angvel(rand < 0.5 ? -1.0 : 1.0) do
        sleep(2.0) do
          speed 1.0
          angvel(0.0)
          @state = :dummy_accel_once
        end
      end
    end
    
    def dummy_accel_once
      @state = :wait
      sleep(1.5) { @state = :dummy_forward }
    end
  end
  
  module SmartStates
    attr_accessor :path
    
    def smart
      @idx ||= 0
      if @goal
        
        #puts "Tank at: #{@tank.x}, #{@tank.y} Goal at: #{@goal.x}, #{@goal.y}"
        new_path = check(:search, 100* $options.refresh, @path){ hq.map.search(@tank, @goal) }
        @path = new_path || @path
        @group ||= PfGroup.new
        @dest ||= [@tank.x, @tank.y]
        
        if @path.size > 2
          refresh($options.refresh) do
            #puts "Calculating distance to #{@dest[0]},#{@dest[1]}"
            dist = Math::sqrt((@dest[0] - @tank.x)**2 + (@dest[1] - @tank.y)**2)
            #puts "I am #{dist} away from my next destinattion at #{@dest[0]},#{@dest[1]}"
            if dist < 15 then
              last = hq.map.array_to_world_coordinates(@path[0][0], @path[0][1])
              nex = hq.map.array_to_world_coordinates(@path[1][0], @path[1][1])
              difference = nex[0]-last[0],nex[1]-last[1]
              nex_idx = 1
              @path.each_with_index do |pos, idx|
                cand = hq.map.array_to_world_coordinates(pos[0],pos[1])
                cand_diff = cand[0]-nex[0],cand[1]-nex[1]
                if cand_diff[0] == difference[0] and cand_diff[1] == difference[1] then
                  nex = cand
                  nex_idx = idx
                else
                  break
                end
              end
              @path.slice!(0..(nex_idx-1))
              @group = PfGroup.new
              puts "updating goal to be at #{nex[0]},#{nex[1]}"
              @group.add_field(Pf.new(nex[0], nex[1], hq.map.world_size, 5, 1))
              @dest = nex
            end
          end
        else
          #puts "Updating goal to be at the goal"
          @group = PfGroup.new
          @group.add_field(Pf.new(@goal.x, @goal.y, hq.map.world_size, 5, 1))
        end
        move = @group.suggest_move(@tank.x, @tank.y, @tank.angle)
        speed move.speed
        angvel move.angvel
      else
        @state = :smart_look_for_enemy_flag
      end
    end
    
    def smart_look_for_enemy_flag
      if hq.enemy_flag_exists?
        puts "Enemy flags:"
        p hq.enemy_flags
        @goal = hq.enemy_flags.randomly_pick(1).first
        @state = :smart
      else
        # Remain in :smart_look_for_enemy_flag state otherwise
      end
    end
    
    def smart_return_home
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
      
      puts "\nStarting agent #{@tank.index}: #{@state}"
      
      # Change state up to every +refresh+ seconds
      EventMachine::PeriodicTimer.new($options.refresh) do
        #puts "Agent #{@tank.index} entering state #{@state.inspect}"
        send(@state)
      end
    end

    # Check if we have fresh enough data, otherwise execute the block
    def check(symbol, freshness, default)
      if (Time.now - last_checked(symbol)) > freshness then
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
        puts "Failed to find method '#{m}'"
        raise NameError
      end
    end
  end
  
end
