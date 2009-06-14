module BraveZealot
  module SeekStates
    attr_accessor :path
    
    def seek
      seek_enemy_flag if @goal.nil?
      
      hq.periodic_action(2.5, 3) do
        @path = hq.map.search(@tank, @goal)
        hq.map.randomize_path!(@path) if $options.random_path
      end
      smart_follow_path
      # transition(:smart, :smart_follow_path)
    end
    
    def seek_fast
      if @path.nil?
        @state = :seek
        return
      end
      
      if (@path = hq.map.search(@tank, @goal))
        if path.size >= 2
          move = smart_move_to(path[0].vector_to(path[1]))
      
          speed move.speed
          angvel move.angvel
        end
        
        transition(:smart_follow_path, :smart_look_for_enemy_flag) if @path.empty?
      end
    end
    
    def seek_slow
      parts = @path[0..10].size
      avg = @path[0..10].inject(0.0){ |sum, coord| sum + @tank.vector_to(coord).length } / parts
      puts "Here: #{@tank.x}, #{@tank.y}"
      puts "Average dist from here: #{avg}"
    
      distance = @tank.vector_to(path.first).length
      while !@path.empty? and distance < 30
        distance = @tank.vector_to(@path.shift).length
      end 
    
      group = PfGroup.new
      group.add_field(Pf.new(@waypoint.x, @waypoint.y, hq.map.world_size, 5, 1))
      move = group.suggest_fastest_move(@tank.x, @tank.y, @tank.angle)
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
    
    def angle_diff(x, y)
      Math.atan2(Math.sin(x - y), Math.cos(x - y))
    end
      
    def smart_vector_move(vector)
      # river_current = coord.vector_to(next_coord)
      # direction = @tank.vector_to(coord)
      # 
      # alpha = 0.0
      # # alpha = 0.5
      # # alpha = 30 / [30, direction.length].max
      # hybrid = Vector.new(alpha * direction.x + (1 - alpha) * river_current.x,
      #                     alpha * direction.y + (1 - alpha) * river_current.y)
      # 
      delta = angle_diff(vector.angle, @tank.angle)
      # 
      # puts "current | x: #{@tank.x}, y: #{@tank.y}, angle: #{@tank.angle}"
      # puts "river_current angle: #{river_current.angle}"
      # puts "direction angle: #{direction.angle}"
      # puts "alpha: #{alpha}"
      # puts "hybrid angle: #{hybrid.angle}"
      # puts "delta angle: #{delta}"
      # puts "distance: #{direction.length}"
      
      return Move.new(1.0, delta / (15 * $options.refresh))
    end
    
  end
  
end