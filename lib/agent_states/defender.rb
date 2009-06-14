
module BraveZealot
  module DefenderStates
    # need to determine whether the enemy is in a corner or in the middle, since the position will dictate the defender path.
    def defender()
			puts "defender() - #{@tank.index}"
			defender_set_goal()
			@state = :defender_move_to_start
    end

    def defender_move_to_start
			puts "defender_move_to_start() - #{@tank.index}"
			if defender_goal_reached()
				#@state = :huntc
				puts "reached goal"
			else
		    move = @group.suggest_move(@tank.x, @tank.y, @tank.angle)
		    
		    speed move.speed
		    angvel move.angvel
				@state = :defender_move_to_start
			end
    end

    #
    #
    #
    # NOTE: the following methods do not represent states
    #
    #
    #
    def defender_goal_reached(threshold = 5)
      dist = calc_dist(@tank,@goal)
#       #puts "Distance to goal = #{dist}"
      return dist < threshold
    end

		def defender_set_goal()
		  # calculate a new destination
		  x, y = defender_calculate_starting_point()
		  @goal = Coord.new(x, y)

		  # reset the potential fields group
		  @group = PfGroup.new(false)
      @group.add_field(Pf.new(@goal.x, @goal.y, @hq.map.world_size, 5, 1))

			return @goal
		end		

    def defender_calculate_starting_point()
      # I'll hard code everything for this map just to do a proof of concept
			# NOTE: this is only valid for Four L's starting as the green team

			if (@tank.index == 0 || @tank.index = 1)
		    x = 190
		    y = 190
			elsif (@tank.index == 2 || @tank.index = 3)
		    x = 190
		    y = -190
			elsif (@tank.index == 4 || @tank.index = 5)
		    x = 230
		    y = 0
			elsif (@tank.index == 6 || @tank.index = 7)
		    x = 390
		    y = 390
			else
		    x = @tank.x
		    y = @tank.y
			end

      return x, y
    end

  end
end
