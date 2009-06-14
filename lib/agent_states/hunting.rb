bzrequire 'lib/communicator'
bzrequire 'lib/agent'

module BraveZealot
  module HuntingStates
    #hunt the closest enemy tank

		MAX_ENEMIES_THRESHOLD = 0	# max number of enemy tanks that can still be alive before
														  # attempting to capture the flag
		DECOY_TANK_INDEX = 0			# index for the tank that will act as the decoy
		START_DECOY_DELAY = 3			# amount of time (seconds) to wait before starting the decoy
		CAPTURE_FLAG_INDEX_THRESHOLD = 1		# all tanks index below this number will be sent to capture
															# the flag, all equal to or above will be sent to defend our flag
		DECOY_TIMER = 60					# amount of time (seconds) to run the decoy for
		TARGET_TIMEOUT = 8				# amount of time (seconds) to wait before selecting a new target
		FUDGE_FACTOR = 1.3				# our margin of error on our calculations..
		BULLET_VELOCITY = 100			# meters per second..

		# state
    def hunter
			puts "#{@tank.index} hunter"

      angvel 0
      speed 0

			@private_goal = nil
			@hunter_timer = nil
      @hunter_target = nil
			@hunter_target_timeout = 0		# measured in seconds

			# initializes hunter_target_timeout
			hunter_set_target_timer()

			#if @tank.index == 8 or @tank.index == 9
			if @tank.index == DECOY_TANK_INDEX
				if @hunter_decoy_timer.nil?
					@hunter_decoy_timer = Time.now.to_f
				end
			end

			@state = :hunter_select_target
			puts "#{@tank.index} hunter -> hunter_select_target"
    end

		# state
		def hunter_select_target
			puts "#{@tank.index} hunter_select_target"

      refresh($options.refresh) do

				# send out our decoy after x number of seconds..
				if @tank.index == DECOY_TANK_INDEX
					puts "#{@tank.index} lapsed time = #{Time.now.to_f - @hunter_decoy_timer}"
					if (Time.now.to_f - @hunter_decoy_timer) > START_DECOY_DELAY
						@hunter_decoy_timer = nil
						@state = :hunter_decoy
						puts "#{@tank.index} hunter_select_target -> hunter_decoy"
						next
					end
				end

				# send out our capture the flag agents.. when we're down to a couple of enemies
				if (enemies_alive <= MAX_ENEMIES_THRESHOLD) 
					puts "#{@tank.index} enemies_alive = #{enemies_alive}"
					if @tank.index < CAPTURE_FLAG_INDEX_THRESHOLD
						goal_enemy_flag()
						@state = :hunter_capture_flag
						puts "#{@tank.index} hunter_select_target -> hunter_capture_flag"
					else
						goal_home_base
						@state = :hunter_return_to_base
						puts "#{@tank.index} hunter_select_target -> hunter_return_to_base"
					end
					next
				end

				if do_we_need_to_find_a_new_target?
					puts "#{@tank.index} selecting new target"
					#hunter_select_closest_target()
					hunter_select_random_target()
					hunter_set_target_timer()
				end

        unless @hunter_target.nil? then
          @state = :hunter_find_range
					puts "#{@tank.index} hunter_select_target -> hunter_find_range"
        end
      end
		end

		def enemies_alive
			count = 0

			@hq.map.othertanks.each do |enemy|
				if enemy.alive?
					count = count + 1
				end
			end
	
			puts "enemies_alive = #{count}"
			return count
		end

		def hunter_target_timedout?
			current = Time.now.to_f
			return current > @hunter_target_timeout
		end

		def hunter_set_target_timer()
			@hunter_target_timeout = Time.now.to_f + TARGET_TIMEOUT
		end

		def do_we_need_to_find_a_new_target?

			decoy_timer_expired = false

			if @tank.index == DECOY_TANK_INDEX
				# puts "#{@tank.index} lapsed time = #{Time.now.to_f - @hunter_decoy_timer}"
				if (Time.now.to_f - @hunter_decoy_timer) > START_DECOY_DELAY
					decoy_timer_expired = true
					puts "#{@tank.index} decoy_timer_expired"
				end
			end

			return (hunter_target_timedout? or @hunter_target.nil? or not @hunter_target.alive? or decoy_timer_expired)
		end

		def hunter_select_random_target()
			new_target = rand(@hq.map.othertanks.size)
			while @hq.map.othertanks[new_target].alive? == false
				new_target = rand(@hq.map.othertanks.size)
			end
			@hunter_target = @hq.map.othertanks[new_target]
			#puts "#{@tank.index} @hunter_target.status = #{@hunter_target.status}"

			if (@hunter_target.nil?)
				puts "#{@tank.index} @hunter_target = @hq.map.othertanks[new_target]"
				Process.exit
			end
		end
	
		def hunter_select_closest_target()
      myc = @tank.to_coord
      distance = 100000

      @hq.map.othertanks.each do |et|
        if et.alive? then
          dt = myc.vector_to(et.to_coord).length
          if ( dt < distance ) then
            distance = dt
            @hunter_target = et
						if (@hunter_target.nil?)
							puts "#{@tank.index} @hunter_target = et"
							Process.exit
						end
          end
        end
      end
		end

		# state
    def hunter_find_range
			puts "#{@tank.index} hunter_find_range"

			if (do_we_need_to_find_a_new_target?)
				puts "#{@tank.index} selecting new target"
				@state = :hunter
				puts "#{@tank.index} hunter_find_range -> hunter"
				return
			end

      #these are the ranges we will check
      range_options = [0.25, 0.50, 0.75, 1.0, 1.25, 1.50, 1.75, 2.00, 2.50]

      refresh($options.refresh) do
        range_options.each do |to|

					if @hunter_target.nil?
						@state = :hunter
						puts "#{@tank.index} error: our hunter_target somehow went nil.."
						puts ".\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n"
						puts "#{@tank.index} hunter_find_range -> hunter"
						next
					end

          #expected position
          #puts "Step 4: epx=#{@hunter_target.x}, epy=#{@hunter_target.y}"
          ep = @hunter_target.kalman_predicted_mu(to)

          #puts "expected position after #{to}sec #{ep.inspect}"
          epc = Coord.new(ep[0], ep[3])
          #puts "Step 5: to=#{to} epx=#{epc.x}, epy=#{epc.y}"

          #figure out how long the bullet has to travel
          d = @tank.to_coord.vector_to(epc).length
          ###puts "distance from me #{@tank.to_coord.inspect} is #{d}"
          eta = d / BULLET_VELOCITY
          #puts "eta = #{eta}"

          #figure out how long we have to turn for
          diff = hunter_calc_diff(epc)
          #puts "diff=#{diff}"
          
          ###puts "total estimated time for kill = #{ett.abs + eta}"

          if (diff.abs * FUDGE_FACTOR + eta) < to then
            @hunter_range = to
            @state = :hunter_hone_angle
						puts "#{@tank.index} hunter_find_range -> hunter_hone_angle"
            ###puts "found range to be #{@hunter_range}"
            hunter_hone_angle
          end
        end
				shoot
      end
			# this state doesn't exist..
      #@state = :huntx if @hunter_target.nil?
    end

    def hunter_hone_angle
			puts "#{@tank.index} hunter_hone_angle"

			# it seems like at this point we should reset the refresh timer
			# for this thread to a small period of time before we expect to
			# have to issue the shot.. otherwise, since this is all single threaded
			# we'd have to spin lock it to be able to control when we're going to fire
			# our shots accurately

			# shot strategy
			# seems like we'd want to fire a burst of shots spaced slightly from each other..
			# rather than just taking one shot, i guess the refresh interval should be
			# sufficient
      refresh($options.refresh) do
        @hq.refresh(:othertanks, $options.refresh) do

					if @hunter_target.nil?
						@state = :hunter
						puts "#{@tank.index} error: our hunter_target somehow went nil.."
						puts ".\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n"
						puts "#{@tank.index} hunter_hone_angle -> hunter"
						next
					end

          ep = @hunter_target.kalman_predicted_mu(@hunter_range)
          epc = Coord.new(ep[0], ep[3])

          d = @tank.to_coord.vector_to(epc).length
          eta = d/BULLET_VELOCITY

          diff = hunter_calc_diff(epc)
          #puts "I need to travel through #{diff} radians to get my optimal angle"

          if diff.abs < $options.refresh then
            #puts "Taking the shot - turn for #{diff}sec and then shoot - eta=#{eta}"
            angvel((diff < 0.0) ? -1 : 1)
            EventMachine::Timer.new(diff) do 
              angvel 0
              EventMachine::Timer.new(@hunter_range - diff - eta) do
                shoot
              end
            end
            #@state = :hunter
						#puts "#{@tank.index} hunter_hone_angle -> hunter"
          else
            if (eta + diff) < @hunter_range then
              n = diff / (2*$options.refresh)
              #puts "setting my angvel to #{n}"
              angvel n
            end
          end
          @state = :hunter_find_range
					puts "#{@tank.index} hunter_hone_angle -> hunter_find_range"
        end
	      #shoot
      end
    end

    def hunter_calc_diff(p)
      ###puts "my=#{@tank.to_coord.inspect} pointing at #{p.x},#{p.y}"
      #perfect angle to shoot
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

    def hunter_decoy
			puts "#{@tank.index} hunter_decoy"

			if (enemies_alive <= MAX_ENEMIES_THRESHOLD) 
				# retarget immediately so we can get moving..
				@state = :hunter
				return
			end

			if @hunter_timer.nil?
				puts "#{@tank.index} set hunter timer"
				@hunter_timer = Time.now.to_f
				puts "#{@tank.index} hunter_decoy -> hunter"
			end

			#puts "lapsed time = #{Time.now.to_f - @hunter_timer.to_f}"
			if (Time.now.to_f - @hunter_timer.to_f) > DECOY_TIMER
				@state = :defender
				puts "#{@tank.index} hunter_decoy -> defender"
				return
			end

      #puts "cv2 - iteration"
      #puts "\ttank.vx, tank.vy = #{tank.vx}, #{tank.vy}"
      speed(0.5)
      angvel(-0.5)
			shoot
    end

		# state
		def hunter_capture_flag
			puts "#{@tank.index} hunter_capture_flag"

			if @hq.flag_possession?
				goal_home_base
				@state = :hunter_return_to_base
				puts "#{@tank.index} hunter_capture_flag -> hunter_return_to_base"
			else
		    move = @group.suggest_move(@tank.x, @tank.y, @tank.angle)
		    
		    speed move.speed
		    angvel move.angvel
			end
    end

		def goal_enemy_flag
				goal = Coord.new(@hq.enemy_flags.first.x, @hq.enemy_flags.first.y)
				hunter_set_goal(goal)

				@group = PfGroup.new(false)
				@group.add_obstacles(@hq.map.obstacles)
		    @group.add_field(Pf.new(hunter_get_goal().x, hunter_get_goal().y, @hq.map.world_size, 5, 1))
		end

		def goal_home_base
			goal = Coord.new(@hq.my_base.center.x, @hq.my_base.center.y)
			hunter_set_goal(goal)

			@group = PfGroup.new(false)
			@group.add_obstacles(@hq.map.obstacles)
			@group.add_field(Pf.new(hunter_get_goal().x, hunter_get_goal().y, @hq.map.world_size, 5, 1))
		end

		def hunter_return_to_base
			puts "#{@tank.index} hunter_return_to_base"

			if hunter_goal_reached()
				hunter_set_goal(nil)
				@group = nil

				@state = :hunter_defend_flag
				puts "#{@tank.index} hunter_return_to_base -> hunter_defend_flag"
			else
		    move = @group.suggest_move(@tank.x, @tank.y, @tank.angle)
		    
		    speed move.speed
		    angvel move.angvel
			end
    end

		# state
		def hunter_defend_flag
			puts "#{@tank.index} hunter_defend_flag"

			hunter_set_goal(nil)
			@state = :hunter
			puts "#{@tank.index} hunter_defend_flag -> hunter"
		end

		
		def hunter_goal_reached(threshold = 5)
		  dist = calc_dist(@tank, hunter_get_goal())
		  #puts "Distance to goal = #{dist}"
		  return dist < threshold
		end
		
		def hunter_set_goal(g)
			@private_goal = g
		end

		def hunter_get_goal()
			return @private_goal
		end
  end
end
