module BraveZealot
  module DecoyStates
    # need to determine whether the enemy is in a corner or in the middle, since the position will dictate the decoy path.
    def decoy()
      set_decoy_goal_point
    end

    def decoy_move_to_start
      unless enemy_tanks_alive then
        @state = :dummy
        return
      end

      set_decoy_starting_point
    end

    def decoy_move_to_goal

      # determine whether we've reached the goal, if so, transition
      unless enemy_tanks_alive() then
        # transition to the next state
        @state = :dummy
        return
      end
      set_decoy_goal_point
    end

    #
    #
    #
    # NOTE: the following methods do not represent states
    #
    #
    #
    def goal_reached(threshold = 5)
      dist = calc_dist(@tank,@goal)
#       #puts "Distance to goal = #{dist}"
      return dist < threshold
    end

    def tank_moving()
      return (@tank.vx == 0 and @tank.vy == 0)
    end

    def calculate_decoy_starting_point()
      # figure out where the flag is
      # should give us back x, y coordinates, then
      # figure out the orientation (ie which which part of the map is open.. (since it could easily be rotated)
      # 
      # I'll hard code everything for this map just to do a proof of concept

      x = 100
      y = -395
      return x, y
    end

    def calculate_decoy_ending_point()
      x = 100
      y = 395

      return x, y
    end

    def set_decoy_starting_point
        # reset the potential fields group
        @group = PfGroup.new(false)

        # calculate a new destination
        x, y = calculate_decoy_starting_point()
        @goal = Coord.new(x, y)
        #@group.add_field(Pf.new(@goal.x, @goal.y, hq.map.world_size, 1, 1.0))

        # transition to the next state
        push_next_state(:smart, :decoy_move_to_goal)
        @state = :smart
    end

    def set_decoy_goal_point
        # reset the potential fields group
        @group = PfGroup.new(false)

        # calculate a new destination
        x, y = calculate_decoy_ending_point()
        @goal = Coord.new(x, y)
        #@group.add_field(Pf.new(@goal.x, @goal.y, hq.map.world_size, 1, 1.0))

        # transition to the next state
        push_next_state(:smart, :decoy_move_to_start)
        @state = :smart
    end
  end
end