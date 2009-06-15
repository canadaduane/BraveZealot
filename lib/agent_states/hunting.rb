bzrequire 'lib/communicator'
bzrequire 'lib/agent'

module BraveZealot
  module HuntingStates
    #hunt the closest enemy tank

		MAX_ENEMIES_THRESHOLD = 0	# max number of enemy tanks that can still be alive before
														  # attempting to capture the flag
		CAPTURE_FLAG_INDEX_THRESHOLD = 5		# all tanks index below this number will be sent to capture
															# the flag, all equal to or above will be sent to defend our flag
		TARGET_TIMEOUT = 8				# amount of time (seconds) to wait before selecting a new target
		FUDGE_FACTOR = 1.3				# our margin of error on our calculations..
		BULLET_VELOCITY = 100			# meters per second..
		DECOY_START_DELAY = 60		# amount of time to delay before activating the decoys
		ENABLE_RANDOM_SHOTS = true

		TRACE_LEVEL = 6
		DEBUG_LEVEL = 5
		INFO_LEVEL = 4
		WARN_LEVEL = 3
		ERROR_LEVEL = 2
		FATAL_LEVEL = 1
		OFF_LEVEL = 0
		

		# state
    def hunter

			$log_level = INFO_LEVEL

			trace "hunter"

      angvel 0
      speed 0

			@private_goal = nil
			@hunter_timer = nil
      @hunter_target = nil
			@hunter_target_timeout = 0		# measured in seconds

			# initializes hunter_target_timeout
			hunter_set_target_timer()

			if @hunter_decoy_timer.nil?
				@hunter_decoy_timer = Time.now.to_f
			end

			@state = :hunter_select_target
			debug "hunter -> hunter_select_target"
    end

		# state
		def hunter_select_target
			trace "hunter_select_target"

      refresh($options.refresh) do

				if @tank.index == $decoy_index
					@state = :hunter_decoy
					debug "hunter_select_target -> hunter_decoy"
					next
				end
	
				# send out our capture the flag agents.. when we're down to a couple of enemies
				if (enemies_alive <= MAX_ENEMIES_THRESHOLD) 
					trace "enemies_alive = #{enemies_alive}"
					if @tank.index < CAPTURE_FLAG_INDEX_THRESHOLD
						goal_enemy_flag()
						@state = :hunter_capture_flag
						debug "hunter_select_target -> hunter_capture_flag"
					else
						goal_home_base()
						@state = :hunter_return_to_base
						debug "hunter_select_target -> hunter_return_to_base"
					end
					next
				end

				if do_we_need_to_find_a_new_target?
					trace "selecting new target"

					update_decoy

					# i have some other targeting algorithms in mind, but random
					# works much better than closest and our kill rates are high enough
					# to justify not doing the extra work..
					#hunter_select_closest_target()
					hunter_select_random_target()

					hunter_set_target_timer()
				end

        unless @hunter_target.nil? then
          @state = :hunter_find_range
					debug "hunter_select_target -> hunter_find_range"
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
	
			trace "enemies_alive = #{count}"
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

			if ($decoy_index == @tank.index)
				trace "decoy timer expired"
				return true
			end

			return (hunter_target_timedout? or @hunter_target.nil? or (not @hunter_target.alive?))
		end

		def hunter_select_random_target()
			new_target = rand(@hq.map.othertanks.size)
			while @hq.map.othertanks[new_target].alive? == false
				new_target = rand(@hq.map.othertanks.size)
			end
			@hunter_target = @hq.map.othertanks[new_target]
			#trace "@hunter_target.status = #{@hunter_target.status}"

			if (@hunter_target.nil?)
				fatal "@hunter_target = @hq.map.othertanks[new_target]"
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
							fatal "@hunter_target = et"
							Process.exit
						end
          end
        end
      end
		end

		# state
    def hunter_find_range
			trace "hunter_find_range"

			if (do_we_need_to_find_a_new_target?)
				trace "selecting new target"
				@state = :hunter
				trace "hunter_find_range -> hunter"
				return
			end

      #these are the ranges we will check
      range_options = [0.25, 0.50, 0.75, 1.0, 1.25, 1.50, 1.75, 2.00, 2.50]

      refresh($options.refresh) do
        range_options.each do |to|

					if @hunter_target.nil?
						@state = :hunter
						error "error: our hunter_target somehow went nil.."
						error ".\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n"
						error "hunter_find_range -> hunter"
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
						debug "hunter_find_range -> hunter_hone_angle"
            ###puts "found range to be #{@hunter_range}"
            hunter_hone_angle
          end
        end

				if (ENABLE_RANDOM_SHOTS)
					log_shot()
					shoot
				end
      end
			# this state doesn't exist..
      #@state = :huntx if @hunter_target.nil?
    end

    def hunter_hone_angle
			trace "hunter_hone_angle"

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
						error "#our hunter_target somehow went nil.."
						error ".\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n.\n"
						error "hunter_hone_angle -> hunter"
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
								# how is this getting reset?
								if @hunter_target.nil?
									log_cancelled_shot
								else
									log_shot()
		              shoot
								end
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
					debug "hunter_hone_angle -> hunter_find_range"
        end

				if (ENABLE_RANDOM_SHOTS)
					log_shot()
					shoot
				end
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
			trace "hunter_decoy"

			if (enemies_alive <= MAX_ENEMIES_THRESHOLD) 
				# retarget immediately so we can get moving..
				@state = :hunter
				return
			end

			if @hunter_timer.nil?
				trace "set hunter timer"
				@hunter_timer = Time.now.to_f
				debug "hunter_decoy -> hunter"
			end

      #puts "cv2 - iteration"
      #puts "\ttank.vx, tank.vy = #{tank.vx}, #{tank.vy}"
      speed(0.5)
      angvel(-0.5)
			shoot
    end

		# state
		def hunter_capture_flag
			trace "hunter_capture_flag"

			if @hq.we_have_enemy_flag?
				goal_home_base
				@state = :hunter_return_to_base
				debug "hunter_capture_flag -> hunter_return_to_base"
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
			trace "hunter_return_to_base"

			if hunter_goal_reached()
				hunter_set_goal(nil)
				@group = nil

				@state = :hunter_defend_flag
				debug "hunter_return_to_base -> hunter_defend_flag"
			else
		    move = @group.suggest_move(@tank.x, @tank.y, @tank.angle)
		    
		    speed move.speed
		    angvel move.angvel
			end
    end

		# state
		def hunter_defend_flag
			trace "hunter_defend_flag"

			hunter_set_goal(nil)
			@state = :hunter
			debug "hunter_defend_flag -> hunter"
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

		# it feels like this should be done at a higher level
		# than this, but I'm not sure how to integrate it in best with
		# the existing code, so I'm just going to do it this way..
		def update_decoy()

			if $decoy_active.nil?
				$decoy_active = false
				$decoy_index = -1

				# really this should be dependent on the amount of noise from the opponent..
				# but since I don't think I can access that information, i'm opting to do it
				# this way..
				if @hq.map.othertanks.size > 10
					$decoy_start_time = Time.now.to_f + DECOY_START_DELAY
				else
					$decoy_start_time = Time.now.to_f
				end
			end

			if $decoy_start_time > Time.now.to_f
				return
			end

			if $decoy_active
				# verify the decoy is still alive, if so, then return immediately
				if @hq.agents[$decoy_index].tank.status == 'normal'
					return
				else
					$decoy_active = false
					$decoy_index = -1
				end
			end

			if $decoy_active == false
				@hq.agents.each do |agent|
					if agent.tank.status == 'normal'
						$decoy_active = true
						$decoy_index = agent.tank.index
						break
					end
				end
			end
		end
		#
		# logging code
		#

		def trace(msg)
			if ($log_level >= TRACE_LEVEL)
				puts "trace #{@tank.index} #{msg}"
			end
		end
		def debug(msg)
			if ($log_level >= DEBUG_LEVEL)
				puts "debug #{@tank.index} #{msg}"
			end
		end
		def info(msg)
			if ($log_level >= INFO_LEVEL)
				puts "info  #{@tank.index} #{msg}"
			end
		end
		def warn(msg)
			if ($log_level >= WARN_LEVEL)
				puts "warn  #{@tank.index} #{msg}"
			end
		end
		def error(msg)
			if ($log_level >= ERROR_LEVEL)
				puts "error #{@tank.index} #{msg}"
			end
		end
		def fatal(msg)
			if ($log_level >= FATAL_LEVEL)
				puts "fatal #{@tank.index} #{msg}"
			end
		end

		def log_shot()
			debug "shot fired at: #{@hunter_target.callsign}, #{@hunter_target.status}"
		end

		def log_cancelled_shot()
			debug "cancelled shot"
		end
  end
end
