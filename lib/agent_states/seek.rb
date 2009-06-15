module BraveZealot
  module SeekStates
    attr_accessor :path
    
    def seek
      # Look for the enemy flag if no goal is currently set
      seek_enemy_flag if @goal.nil?
      
      # Update the larger path plan every second or so
      periodically(5.0) { seek_update_path }
      
      # Default to a fast-action agent
      transition(:seek, :seek_fast)
    end
    
    def seek_update_path
      if (new_path = hq.map.search(@tank, @goal, 0, true))
        @path = new_path
        @waypoint = nil
      else
        puts "no path found"
      end
    end
    
    def seek_fast
      if @tank.vector_to(@goal).length <= @proximity
        transition(:seek_fast, :seek_done)
      else
        seek_update_path
        if @path
          if @path.size >= 10
            @waypoint ||= @path[9]
            
            @short_path = hq.map.search(@tank, @waypoint)
            if @short_path && @short_path.size > 4
            
              move = seek_vector_move(@short_path[2].vector_to(@short_path[4]))
            
              speed move.speed
              angvel move.angvel
            end
          else
            @short_path = nil # so it doesn't show up on the pdf output
            transition(:seek_fast, :seek_field)
          end
        else
          # If @path is nil, try again to find a way to the goal
          seek_update_path
        end
      end
    end
    
    def seek_field
      distance = @tank.vector_to(@goal).length
      if distance <= @proximity
        transition(:seek_field, :seek_done)
      elsif distance > 50
        transition(:seek_field, :seek_fast)
      else
        group = PfGroup.new
        group.add_field(Pf.new(@goal.x, @goal.y, hq.map.world_size, 5, 1))
        move = group.suggest_move(@tank.x, @tank.y, @tank.angle)
      
        speed move.speed
        angvel move.angvel
      end
    end
    
    def seek_done
      puts "\nseek arrived\n"
      transition(:seek_done, :wait)
    end
    
    protected
    
    def seek_vector_move(vector)
      delta = vector.angle_diff(@tank)
      # puts "current | x: #{@tank.x}, y: #{@tank.y}"
      # puts "current angle: #{@tank.angle}, angvel: #{@tank.angvel}"
      # puts "target angle: #{vector.angle}"
      # puts "delta: #{delta}"
      
      if delta.abs > Math::PI / 2
        speed = -1.0
      else
        speed = 1.0
      end
      # speed *= ( 2 * ( Math::PI - delta.abs() ).abs() / Math::PI - 1 )
      
      angvel = delta / (5 * $options.refresh)
      
      # puts "suggested speed: #{speed}, angvel: #{angvel}"
      
      return Move.new(speed, angvel)
    end
    
  end
  
end