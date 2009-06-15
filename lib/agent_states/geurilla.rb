module BraveZealot
  module GeurillaStates
    TARGET_TIMEOUT = 8        # amount of time (seconds) to wait before selecting a new target
    FUDGE_FACTOR = 1.3        # our margin of error on our calculations..
    BULLET_VELOCITY = 100     # meters per second..

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
      push_next_state(:seek_done, :geurilla_take_cover_done)
      puts " geurilla_take_cover -> seek"
    end

    def geurilla_take_cover_done
      puts " geurilla_take_cover_done -> ?"
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
          if new_col >= 0 and new_col < hq.map.side_length and new_row >= 0 and new_row < hq.map.side_length then
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
      speed 0
      angvel 0
      @geurilla_ranges ||= [0.0, 0.10, 0.25, 0.50, 0.75, 1.0, 1.5, 2.0]
      unless geurilla_enemy_in_range?
        @state = :geurilla_trap_done
      else
        shadow_map = @tank.shadows(hq.map,0.5)
        soonest = 100.0
        soonest_position = nil
        soonest_enemy = nil

        geurilla_closest_enemies.each do |ot|
          @geurilla_ranges.each do |r|
            ep = ot.kalman_predicted_mu(r)
            epc = Coord.new(ep[0], ep[3])
            col,row = hq.map.world_to_array_coordinates(epc.x, epc.y)
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
        if soonest_enemy.nil?
          puts "no solutions available"
          @state = :geurilla_trap_done
        else
          @geurilla_target = soonest_enemy
          geurilla_set_target_timer
          @state = :geurilla_find_range
        end
      end
    end

    def geurilla_target_timedout?
      current = Time.now.to_f
      return current > @geurilla_target_timeout
    end

    def geurilla_set_target_timer()
      @geurilla_target_timeout = Time.now.to_f + TARGET_TIMEOUT
    end

     def geurilla_find_range
      #these are the ranges we will check
      range_options = [0.25, 0.50, 0.75, 1.0, 1.25, 1.50, 1.75, 2.00, 2.50]

      refresh($options.refresh) do
        range_options.each do |to|
          if @geurilla_target.nil?
            puts "Geurilla target is nil... dangit"
            @state = :geurilla_trap_done
            next
          end

          #expected position
          ep = @geurilla_target.kalman_predicted_mu(to)
          epc = Coord.new(ep[0], ep[3])

          #figure out how long the bullet has to travel
          d = @tank.to_coord.vector_to(epc).length
          eta = d / BULLET_VELOCITY

          #figure out how long we have to turn for
          diff = geurilla_calc_diff(epc)

          if (diff.abs * FUDGE_FACTOR + eta) < to then
            @geurilla_range = to
            @state = :geurilla_hone_angle
            geurilla_hone_angle
          end
        end
      end
    end

    def geurilla_hone_angle
      refresh($options.refresh) do
        @hq.refresh(:othertanks, $options.refresh) do

          if @geurilla_target.nil?
            @state = :geurilla_trap_done
            next
          end

          ep = @geurilla_target.kalman_predicted_mu(@geurilla_range)
          epc = Coord.new(ep[0], ep[3])

          d = @tank.to_coord.vector_to(epc).length
          eta = d/BULLET_VELOCITY

          diff = hunter_calc_diff(epc)

          if diff.abs < $options.refresh then
            #puts "Taking the shot - turn for #{diff}sec and then shoot - eta=#{eta}"
            angvel((diff < 0.0) ? -1 : 1)
            EventMachine::Timer.new(diff) do 
              angvel 0
              EventMachine::Timer.new(@geurilla_range - diff - eta) do
                # how is this getting reset?
                unless @geurilla_target.nil?
                  shoot
                  shoot
                end
              end
            end
            #@state = :hunter
            #puts "#{@tank.index} hunter_hone_angle -> hunter"
          else
            if (eta + diff) < @geurilla_range then
              n = diff / (2*$options.refresh)
              #puts "setting my angvel to #{n}"
              angvel n
            end
          end
          @state = :geurilla_trap_done
        end
      end
    end

    def geurilla_calc_diff(p)
      pas = Math.atan2(p.y - @tank.y, p.x - @tank.x)

      if pas < 0.0  then
        pas += 2*Math::PI
      elsif pas > (2*Math::PI) then
        pas -= 2*Math::PI
      end

     #puts "perfect angle to shoot = #{pas} -- my_position=#{@tank.x},#{@tank.y} -> enemy_position=#{p.x},#{p.y}"

      #difference of my angle and perfect angle
      diff = pas - @tank.angle
      #puts "raw diff = #{diff}"
      if diff < -1 * Math::PI then
        diff = 2*Math::PI + diff
        #puts "raw diff < -pi so changed to #{diff}"
      elsif diff > Math::PI then
        diff = -1*(2*Math::PI - diff)
        #puts "raw diff > pi so changed to #{diff}"
      end
      diff
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
          push_next_state(:geurilla_advance_done, :geurilla_status_check)
          @state = :geurilla_advance
        else
          @state = :geurilla_opportunity
        end
      end
    end

    def geurilla_advance
      g = geurilla_goal
      path = hq.map.search(@tank, g, 0, true)

      unless path.nil?
        last_point = nil
        path.each_with_index do |p, idx|
          last_point = p
          if idx >= 10 then
            break
          end
        end

        if last_point.nil? then
          @state = :geurilla_advance_done
        else
          @goal = last_point
          push_next_state(:seek_done, :geurilla_take_cover)
          push_next_state(:geurilla_take_cover_done, :guerilla_advance_done)
          @state = :seek
        end
      else
        @state = :geurilla_advance_done
      end
    end

    def guerilla_advance_done
      transition(:geurilla_advance_done, :guerilla_status_check)
    end

    def geurilla_opportunity
      transition(:geurilla_opportunity, :geurilla_status_check)
    end

    def geurilla_enemy_in_range?
      if geurilla_closest_enemies.empty?
        return false
      else
        dist = @tank.vector_to(geurilla_closest_enemies.first).length
        puts "distance to closest enemy = #{dist}"
        return (dist < 200.0)
      end
    end

    def geurilla_closest_enemies(num_enemies = 5, freshness = 0.4)
      @geurilla_closest_time ||= Time.mktime(0).to_f
      if @geurilla_closest.nil? or (Time.now.to_f - @geurilla_closest_time) > freshness then
        @geurilla_closest_time = Time.now.to_f

        unless hq.map.flags.empty?
          color = hq.map.flags.first.color
          @geurilla_closest = hq.enemies_nearest(Coord.new(@tank.x, @tank.y), color, num_enemies)
        end
        puts "getting closest enemies from HQ #{@geurilla_closest}"
        if @geurilla_closest.nil? then
          @geurilla_closest = []
        end
      end
      @geurilla_closest
    end

    def geurilla_goal
      if @geurilla_goal.nil?
        unless hq.map.flags.empty?
          color = hq.map.flags.first.color
          base = hq.map.get_base(color)
          @geurilla_goal = base.center
        end
      end
      
      #if the goal is still nil then we just return where we are right now
      if @geurilla_goal.nil?
        Coord.new(@tank.x, @tank.y)
      end
      @geurilla_goal
    end
  end
end