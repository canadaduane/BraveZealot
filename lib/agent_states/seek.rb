module BraveZealot
  module SeekStates
    attr_accessor :path
    
    def seek
      # Look for the enemy flag if no goal is currently set
      seek_enemy_flag if @goal.nil?
      
      # Update the larger path plan every second or so
      periodically(1.0) { seek_update_path }
      
      # Default to a fast-action agent
      transition(:seek, :seek_fast)
    end
    
    def seek_update_path
      if (new_path = hq.map.search(@tank, @goal, 0))
        @path = new_path
        @waypoint = nil
      end
    end
    
    def seek_fast
      if @tank.vector_to(@goal).length <= @proximity
        transition(:seek_fast, :seek_arrived)
      else
        seek_update_path
        if @path
          if @path.size >= 10
            @waypoint ||= @path[9]
          
            if @short_path = hq.map.search(@tank, @waypoint)
            
              move = seek_vector_move(@short_path[2].vector_to(@short_path[4]))
            
              speed move.speed
              angvel move.angvel
            end
          else
            transition(:seek_fast, :seek_field)
          end
        else
          # If @path is nil, try again to find a way to the goal
          seek_update_path
        end
      end
    end
    
    def seek_field
      if @tank.vector_to(@goal).length <= @proximity
        transition(:seek_field, :seek_arrived)
      else
        group = PfGroup.new
        group.add_field(Pf.new(@goal.x, @goal.y, hq.map.world_size, 5, 1))
        move = group.suggest_move(@tank.x, @tank.y, @tank.angle)
      
        speed move.speed
        angvel move.angvel
      end
    end
    
    def seek_arrived
      puts "\nseek arrived\n"
      transition(:seek_arrived, :seek_enemy_flag)
    end
    
    def seek_enemy_flag
      if hq.enemy_flag_exists?
        @goal = hq.enemy_flags.randomly_pick(1).first
        puts "Seeking enemy flag: #{@goal.color} at (#{@goal.x}, #{@goal.y})"
        transition(:seek_enemy_flag, :seek)
      else
        # Remain in :smart_look_for_enemy_flag state otherwise
      end
    end
    
    def seek_home_base
      @goal = hq.my_base.center
      puts "Seeking home base: (#{@goal.x}, #{@goal.y})"
      transition(:seek_home_base, :seek)
    end
    
      
    def seek_vector_move(vector)
      delta = vector.angle_diff(@tank)
      # puts "current | x: #{@tank.x}, y: #{@tank.y}"
      # puts "current angle: #{@tank.angle}, angvel: #{@tank.angvel}"
      # puts "target angle: #{vector.angle}"
      # puts "delta: #{delta}"
      
      return Move.new(1.0, delta * 3) #/ (10 * $options.refresh))
    end
    
  end
  
end