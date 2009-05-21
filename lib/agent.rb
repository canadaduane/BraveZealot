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
    def smart
      @idx ||= 0
      if @goal
        puts "Tank at: #{@tank.x}, #{@tank.y} Goal at: #{@goal.x}, #{@goal.y}"
        new_path = hq.map.search(@tank, @goal)
        @path = new_path || @path
        group = PfGroup.new
        
        if path.size > 10
          n = hq.map.array_to_world_coordinates(path[10][0], path[10][1])
          group.add_field(Pf.new(n[0], n[1], hq.map.world_size, -50, 0.2))
          
          # File.open("map#{@idx += 1}.gpi", "w") do |f|
          #   data = hq.map.to_gnuplot do
          #     puts "prep path: #{path.inspect}"
          #     "\n\n# Path:\n" +
          #     "plot '-' with vectors head\n" +
          #     path.map{ |x, y| x, y = hq.map.array_to_world_coordinates(x, y); "#{x} #{y} #{2} #{2}" }.join("\n") + "\n"
          #     # group.to_gnuplot_part(hq.map.world_size)
          #   end
          #   puts "Done prep"
          #   f.write data
          # end
          # exit(-1)
        else
          group.add_goal(@goal.x, @goal.y, hq.map.world_size)
        end
        move = group.suggest_move(@tank.x, @tank.y, @tank.angle)
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
        puts "Agent #{@tank.index} entering state #{@state.inspect}"
        send(@state)
      end
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
        puts "Failed to find #{m}"
        raise NameError
      end
    end
  end
  
end
