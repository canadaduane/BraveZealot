bzrequire 'lib/communicator'
require 'ruby-debug'

RADIANS_PER_DEGREE = Math::PI/180

class Array
  # If +number+ is greater than the size of the array, the method
  # will simply return the array itself sorted randomly
  def randomly_pick(number)
    sort_by{ rand }.slice(0...number)
  end
end

module BraveZealot
  module DummyStates
    # Shortcut state for :forward_until_hit
    def dummy
      @state = :dummy_forward
    end
    
    def dummy_forward
      curr_speed = Math.sqrt(@tank.vx**2 + @tank.vy**2)
      # Check if we've hit something
      @state =
        if curr_speed < 24.5
          speed(-0.1)
          :dummy_random_turn
        else
          :dummy_forward
        end
    end
    
    def dummy_random_turn
      angvel(rand < 0.5 ? -1.0 : 1.0) do
        sleep(2.0) do
          speed 1.0
          angvel(0.0)
          @state = :dummy_accel_once
        end
      end
    end
    
    def dummy_accel_once
      @state = :wait
      sleep(1.5) { @state = :dummy_forward }
    end
  end
  
  module SmartStates
    attr_accessor :path
    def smart
      @idx ||= 0
      if @goal
        
        #puts "Tank at: #{@tank.x}, #{@tank.y} Goal at: #{@goal.x}, #{@goal.y}"
        new_path = check(:search, 1000* $options.refresh, @path){ hq.map.search(@tank, @goal) }
        @path = new_path || @path || []
        @group ||= PfGroup.new
        @dest ||= [@tank.x, @tank.y]
        
        if @path.size > 2
          refresh($options.refresh) do
            #puts "Calculating distance to #{@dest[0]},#{@dest[1]}"
            dist = Math::sqrt((@dest[0] - @tank.x)**2 + (@dest[1] - @tank.y)**2)
            #puts "I am #{dist} away from my next destinattion at #{@dest[0]},#{@dest[1]}"
            if dist < 15 then
              last = hq.map.array_to_world_coordinates(@path[0][0], @path[0][1])
              nex = hq.map.array_to_world_coordinates(@path[1][0], @path[1][1])
              difference = nex[0]-last[0],nex[1]-last[1]
              nex_idx = 1
              @path.each_with_index do |pos, idx|
                cand = hq.map.array_to_world_coordinates(pos[0],pos[1])
                cand_diff = cand[0]-nex[0],cand[1]-nex[1]
                if cand_diff[0] == difference[0] and cand_diff[1] == difference[1] then
                  nex = cand
                  nex_idx = idx
                else
                  break
                end
              end
              @path.slice!(0..(nex_idx-1))
              @group = PfGroup.new
              puts "updating goal to be at #{nex[0]},#{nex[1]}"
              @group.add_field(Pf.new(nex[0], nex[1], hq.map.world_size, 5, 1))
              @dest = nex
            end
          end
        else
          #puts "Updating goal to be at the goal"
          @group = PfGroup.new
          @group.add_field(Pf.new(@goal.x, @goal.y, hq.map.world_size, 5, 1))
        end
        move = @group.suggest_move(@tank.x, @tank.y, @tank.angle)
        speed move.speed
        angvel move.angvel
      else
        @state = :smart_look_for_enemy_flag
      end
    end
    
    def smart_look_for_enemy_flag
      if hq.enemy_flag_exists?
        puts "Enemy flags:"
        p hq.enemy_flags
        @goal = hq.enemy_flags.randomly_pick(1).first
        @state = :smart
      else
        # Remain in :smart_look_for_enemy_flag state otherwise
      end
    end
    
    def smart_return_home
      @goal = hq.my_base.center
      @state = :smart
    end
  end

	module DecoyStates
		# need to determine whether the enemy is in a corner or in the middle, since the position will dictate the decoy path.
		def decoy()
			set_decoy_goal_point
			decoy_move_to_start
		end

		def decoy_move_to_start

			# determine whether we've reached the goal, if so, transition
			if goal_reached()
				set_decoy_goal_point
			else
	      move = @group.suggest_move(@tank.x, @tank.y, @tank.angle)
		    speed move.speed
		    angvel move.angvel
			end
		end

		def decoy_move_to_goal

			# determine whether we've reached the goal, if so, transition
			if enemy_tanks_alive() == false
				# transition to the next state
			 	@state = :smart_return_home
				return
			end

			if goal_reached()
				# this has a logic bug in it since if I'm in move_to_start and have killed 
				# the enemies I don't immediate change my behavior, I continue to proceed until
				# I transition back to moving towards the goal before I check the state of whether
				# the enemies are killed
				set_decoy_starting_point
			else
	      move = @group.suggest_move(@tank.x, @tank.y, @tank.angle)
		    speed move.speed
		    angvel move.angvel
			end
		end
		
		#
		#
		#
		# NOTE: the following methods do not represent states
		#
		#
		#
		def goal_reached(threshold = 5)
			return calc_dist(@tank, @goal) < threshold
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
	      @group.add_field(Pf.new(@goal.x, @goal.y, hq.map.world_size, 1, 1.0))

				# transition to the next state
			 	@state = :decoy_move_to_start
		end

		def set_decoy_goal_point
				# reset the potential fields group
	      @group = PfGroup.new(false)

				# calculate a new destination
				x, y = calculate_decoy_ending_point()
	      @goal = Coord.new(x, y)
	      @group.add_field(Pf.new(@goal.x, @goal.y, hq.map.world_size, 1, 1.0))

				# transition to the next state
			 	@state = :decoy_move_to_goal
		end
	end

	module SniperStates
		def sniper
			set_sniper_starting_point
			sniper_move_to_start_position
		end

		def sniper_move_to_start_position
			puts "snipe_move_to_start_position"

			# determine whether we've reached the goal, if so, transition
			if goal_reached(5.5)
				puts "reached starting position"
				speed(0)
				if decoy_is_closer()
					set_sniper_attacking_point()
				else
					# otherwise just wait until it is safe to attack.
				end
			else
				puts "moving towards starting position"
	      move = @group.suggest_move(@tank.x, @tank.y, @tank.angle)
				log_move(move)
		    speed move.speed
		    angvel move.angvel
			end
		end

		def sniper_move_to_attack_position
			puts "snipe_move_to_attack_position"
			# determine whether we've reached the goal, if so, transition
			if goal_reached(5.5)
				puts "reached attack position"
				speed(0)
				# I should be doing a check at this point, but I'm just going to
				# set it in bezerker mode for now
				@state = :sniper_attack
				sniper_attack
			else
				puts "moving into attack position"
	      move = @group.suggest_move(@tank.x, @tank.y, @tank.angle)
				#log_move(move)
		    speed move.speed
		    angvel move.angvel
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
				# capture the flag..
			end
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
      target_angle = Math.atan2(best_enemy.y - @tank.y,
              best_enemy.x - @tank.x)
      relative_angle = normalize_angle(target_angle - @tank.angle)

			return ((relative_angle).abs < RADIANS_PER_DEGREE)
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

			angvel(2 * relative_angle)
		end

		def normalize_angle(angle)
			# Make any angle be between +/- pi.
			angle -= 2 * Math::PI * (angle / (2 * Math::PI))

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
			x = 50
			y = 375
			return x, y
		end

		def calculate_sniper_attacking_position()
			# figure out where the flag is
			# should give us back x, y coordinates, then
			# figure out the orientation (ie which which part of the map is open.. (since it could easily be rotated)
			# 
			# I'll hard code everything for this map just to do a proof of concept
			x = 75
			y = 350
			return x, y
		end

		def set_sniper_starting_point()
			x, y = calculate_sniper_starting_position()
      @goal = Coord.new(x, y)

			# setup the potential fields...
      @group = PfGroup.new(false)

			# attractive field (full weight)
      @group.add_field(Pf.new(x, y, hq.map.world_size, 5, 0.8))

			@state = :sniper_move_to_start_position
		end

		def set_sniper_attacking_point()
			x, y = calculate_sniper_attacking_position()
      @goal = Coord.new(x, y)

			# setup the potential fields...
      @group = PfGroup.new(false)

			# attractive field (full weight)
      @group.add_field(Pf.new(x, y, hq.map.world_size, 5, 0.8))

			# transition to the next state
		 	@state = :sniper_move_to_attack_position
		end
	end

  class Agent
    # hq   :: Headquarters  -> The headquarters object
    # tank :: Tank          -> Data object
    attr_accessor :hq, :tank, :mode

    # state :: Symbol  -> :capture_flag, :home
    # goal :: Coord   -> Coordinate indicating where the agent is headed
    attr_accessor :state, :goal
		attr_accessor :group
    
    include DummyStates
    include SmartStates
		include DecoyStates
		include SniperStates
    
    # See above for definitions of hq and tank
    def initialize(hq, tank, initial_state = nil)
      @hq, @tank = hq, tank
      @state = initial_state || :dummy
      @goal = nil
      
      puts "\nStarting agent #{@tank.index}: #{@state}"
      
      # Change state up to every +refresh+ seconds
      EventMachine::PeriodicTimer.new($options.refresh) do
        #puts "Agent #{@tank.index} entering state #{@state.inspect}"
        send(@state)
      end
    end

    # Check if we have fresh enough data, otherwise execute the block
    def check(symbol, freshness, default)
      if (Time.now - last_checked(symbol)) > freshness then
        checked(symbol,Time.now)
        yield
      else
        default
      end
    end

    def last_checked(symbol)
      @times ||= {}
      @times[symbol] || Time.at(0)
    end

    def checked(symbol,time)
      @times ||= {}
      puts "Refreshing #{symbol}"
      @times[symbol] = time
    end
    
    def wait
      # do nothing
    end
    
    def push_next_state(state, next_state)
      @next_state ||= {}
      @next_state[state] ||= []
      @next_state[state].push next_state
    end
    
    def transition(state, default)
      @next_state ||= {}
      @next_state[state] ||= []
      @state = @next_state[state].shift || default
    end
    
    def refresh(freshness, &block)
      @hq.refresh(:mytanks, freshness, &block)
    end
    
    def sleep(time, &block)
      EventMachine::Timer.new(time, &block)
    end
    
    # Forward certain messages to headquarters, with our tank index
    def method_missing(m, *args, &block)
      if Communicator::COMMANDS.keys.include?(m.to_sym)
        @hq.send(m, @tank.index, *args, &block)
      else
        puts "Failed to find method '#{m}'"
        raise NameError
      end
    end
  end
  
end
