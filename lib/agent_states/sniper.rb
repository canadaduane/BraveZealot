module BraveZealot
  module SniperStates
    def test_shot
      shoot do |shot|
        10.times do |idx|
          shots do |response|
            response.value.each do |s|
              puts "#{idx} -> #{s.inspect}"
            end
          end
        end
      end
      @state = :dummy
    end

    def sniper
      @state = sniper_move_to_start_position
    end

    def sniper_move_to_start_position
      puts "snipe_move_to_start_position"
      set_sniper_starting_point
    end

    def sniper_move_to_attack_position
      puts "snipe_move_to_attack_position"
      speed(0)
      if decoy_is_closer()
        set_sniper_attacking_point
      end
    end

    def log_move(move)
      #puts "input     : tank.x, tank.y, tank.angle = #{@tank.x}, #{tank.y}, #{tank.angle}"
      #puts "suggestion: speed, angvel = #{move.speed}, #{move.angvel}"
      puts "in: (#{@tank.x}, #{tank.y}, #{tank.angle}), out: (#{move.speed}, #{move.angvel})"
    end

    def sniper_attack
      puts "sniper attack"
      if enemy_tanks_alive()
        puts "enemy tanks are alive"
        if enemy_targeted()
          angvel(0)
          speed(0)
          puts "shot fired"
          shoot()
        else
          puts "targeting enemy"
          target_enemy()
        end
      else
        transition(:sniper_attack, :sniper_done)
      end
    end
    
    def sniper_done
      transition(:sniper_done, :wait)
    end

    #
    # NOTE:  The following methods are not considered states
    #
    def enemy_tanks_alive()
      @hq.map.othertanks.each do |enemy_tank|
        if enemy_tank.status != 'dead'
          return true
        end
      end

      return false
    end

    def enemy_targeted
      # if tank is directly pointing at other tank..
      # we'll just turn firing on.. not a good idea for the final solution, but should work.
      puts "@tank.angle = #{@tank.angle}"

      best_enemy = select_target()
      puts "distance to best enemy = #{calc_dist(best_enemy, @tank)}"
      target_angle = Math.atan2(best_enemy.y - @tank.y,
              best_enemy.x - @tank.x)
      relative_angle = normalize_angle(target_angle - @tank.angle)

      puts "target_angle = #{target_angle}"
      return ((relative_angle).abs < 0.001)
    end

    def select_target()
      world_size = 800
      best_enemy = nil
      best_dist = 2.0 * world_size
      @hq.map.othertanks.each do |enemy|

        if enemy.status != 'normal'
          next
        end

        dist = calc_dist(enemy, @tank)

        if dist < best_dist
          best_dist = dist
          best_enemy = enemy
        end
      end

      return best_enemy
    end

    def calc_dist(p1, p2)
      return (Math.sqrt((p1.x - p2.x) ** 2 + (p1.y - p2.y) ** 2))
    end

    def target_enemy
      # the actual angle needs to be calculated..
      # this is where a PD controller would be really nice to have.
      # in addition i really must have the info updated every time it is called 
      # and it should be called continuously at this point.. or it should be 
      # more efficient and predict how long it will be before it rotates into
      # position and sleep until that time

      best_enemy = select_target()
      target_angle = Math.atan2(best_enemy.y - @tank.y,
              best_enemy.x - @tank.x)
      relative_angle = normalize_angle(target_angle - @tank.angle)

      puts "target, tank, relative = #{target_angle}, #{@tank.angle}, #{relative_angle}"      
      puts "angvel = #{2 * relative_angle}"
      angvel(2 * relative_angle)
    end

    def normalize_angle(angle)
      # Make any angle be between +/- pi.
      angle -= 2 * Math::PI * (angle / (2 * Math::PI)).to_i

      if angle <= -Math::PI
        angle += 2 * Math::PI
      elsif angle > Math::PI
        angle -= 2 * Math::PI
      end

      return angle
    end

    def decoy_is_closer
      # make an assumption we only have two tanks, this will
      # need to be modified for future labs when we start adding in more tanks

      decoy_tank = nil

      if @tank.index == 0
        decoy_tank = @hq.agents[1].tank
      else
        decoy_tank = @hq.agents[0].tank
      end
      
      @hq.map.othertanks.each do |enemy_tank|
        if calc_dist(decoy_tank, enemy_tank) > calc_dist(@tank, enemy_tank)
          return false
        end
      end

      return true
    end

    def calculate_sniper_starting_position()
      # figure out where the flag is
      # should give us back x, y coordinates, then
      # figure out the orientation (ie which which part of the map is open.. (since it could easily be rotated)
      # 
      # I'll hard code everything for this map just to do a proof of concept
      x = 115
      y = 325
      return x, y
    end

    def calculate_sniper_attacking_position()
      # figure out where the flag is
      # should give us back x, y coordinates, then
      # figure out the orientation (ie which which part of the map is open.. (since it could easily be rotated)
      # 
      # I'll hard code everything for this map just to do a proof of concept
      x = 150
      y = 270
      return x, y
    end

    def set_sniper_starting_point()
      x, y = calculate_sniper_starting_position()
      @goal = Coord.new(x, y)

      # transition to the next state
      push_next_state(:smart_follow_path, :sniper_move_to_attack_position)
      @state = :smart
    end

    def set_sniper_attacking_point()
      x, y = calculate_sniper_attacking_position()
      @goal = Coord.new(x, y)

      # transition to the next state
      push_next_state(:seek_done, :sniper_attack)
      @state = :seek
    end
  end
end