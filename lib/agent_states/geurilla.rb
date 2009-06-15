module BraveZealot
  module GeurillaStates
    def geurilla
      push_next_state(:geurilla_take_cover_done, :geurilla_status_check)
      @state = :geurilla_take_cover
    end

    def geurilla_take_cover
      world = hq.map.composite_map(0.5)
      col,row = hq.map.world_to_array_coordinates(@tank.x,@tank.y)
      puts "looking for cover from #{col},#{row}"
      col,row = geurilla_find_cover(world,col,row)
      puts "found shadiest spot at #{col},#{row}"
      x,y = hq.map.array_to_world_coordinates(col,row)
      @goal = Coord.new(x,y)
      @state = :seek
      push_next_state(:seek_arrived, :geurilla_take_cover_done)
    end

    def geurilla_take_cover_done
      transition(:geurilla_take_cover_done, :geurilla_status_check)
    end

    def geurilla_wait
      puts "waiting in geurilla mode"
    end

    def geurilla_find_cover(world, col,row)
      current_weight = world[col,row]
      (-11..11).each do |col_mod|
        (-11..11).each do |row_mod|
          new_col = col+col_mod
          new_row = row+row_mod
          if new_col >= 0 and new_col <= hq.map.side_length and new_row >= 0 and new_row <= hq.map.side_length then
            w = world[new_col, new_row]
            if w >= 0 and w < current_weight then
              puts "found shadier spot at #{ new_col },#{ new_row }"
              return geurilla_find_cover(world, new_col, new_row)
            end
          end
        end
      end
      return col, row
    end

    def geurilla_trap
      @geurilla_ranges ||= [0.0, 0.10, 0.25, 0.50, 0.75, 1.0, 1.5, 2.0]
      unless geurilla_enemy_in_range?
        @state = :geurilla_trap_done
      else
        shadow_map = @tank.shadows(0.5)
        soonest = 100.0
        soonest_position = nil
        soonest_enemy = nil

        geurilla_closest_enemies.each do |ot|
          @geurilla_ranges.each do |r|
            ep = ot.kalman_predicted_mu(r)
            epc = Coord.new(ep[0], ep[3])
            col,row = hq.map.world_to_array_coordinates(c.x, c.y)
            if shadow_map[col,row] == 0.0 and r < soonest
              puts "found a solution in #{r} sec @ #{col},#{row}"
              soonest = r
              soonest_position = epc
              soonest_enemy = ot
              break
            end
          end
        end

        # were we unable to find a solution?
        unless soonest_enemy.nil?
          puts "no solutions available"
          @state = :geurilla_trap_done
        else
          push_next_state(:hunter_done, :geurilla_status_check)
          @hunter_target = soonest_enemy
          @hunter_target_timeout = Time.now.to_f + 3.0
          @state = :hunter_find_range
        end
      end
    end

    def geurilla_trap_done
      transition(:geurilla_trap_done, :geurilla_status_check)
    end

    def geurilla_status_check
      puts "Checking status..."
      if geurilla_enemy_in_range?
        push_next_state(:geurilla_trap_done, :geurilla_status_check)
        @state = :geurilla_trap
      else
        goal = geurilla_goal
        if @tank.vector_to(goal).length > 50.0
          puts "I want to advance"
          #push_next_state(:geurilla_advance_done, :geurilla_status_check)
          #@state = :geurilla_advance
        else
          @state = :geurilla_opportunity
        end
      end
    end

    def guerilla_opportunity
      transition(:geurilla_opportunity, :geurilla_status_check)
    end

    def geurilla_enemy_in_range?
      if geurilla_closest_enemies.empty?
        return false
      else
        dist = @tank.vector_to(geurilla_closest_enemies.first).length
        return (dist < 50.0)
      end
    end

    def geurilla_closest_enemies(num_enemies = 5, freshness = 0.4)
      @geurilla_closest_time ||= Time.mktime(0).to_f
      if @geurilla_closest.nil? or (Time.now.to_f - @geurilla_closest_time) > freshness then
        @geurilla_closest_time = Time.now.to_f

        @geurilla_closest = hq.agents_nearest(Coord.new(@tank.x, @tank.y), num_enemies)
        puts "getting closest enemies from HQ #{@geurilla_closest}"
        if @geurilla_closest.nil? then
          @guerilla_closest = []
        end
      end
      @guerilla_closest
    end

    def guerilla_goal
      if @guerilla_goal.nil?
        unless hq.map.flags.empty?
          color = hq.map.flags.first.color
          base = hq.map.get_base(color)
          @guerilla_goal = base.center
        end
      end
      
      #if the goal is still nil then we just return where we are right now
      if @geurilla_goal.nil?
        Coord.new(@tank.x, @tank.y)
      end
      @guerilla_goal
    end
  end
end