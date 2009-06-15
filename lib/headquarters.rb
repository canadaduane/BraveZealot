bzrequire 'lib/communicator'
bzrequire 'lib/map_discrete'
bzrequire 'lib/agent'
bzrequire 'lib/pf_group'

module BraveZealot
  class Headquarters < Communicator
    attr_reader :map, :my_color, :my_base, :mytanks_time, :agents
    
    class MissingData < Exception; end
    
    def start
      @agents = []                # Current BraveZealot::Agent objects
      @world_time = -1.0           # Last communicated world time
      @clock = Time.mktime(1970)  # set the clock to be old-school
      @message_times = {}         # Last time we received a message (in Time.now units)
      
      install_signal_trap
      
      # Gather initial world data... which team are we?  how big is the map?
      constants do |r|
        world_size = nil
        r.constants.each do |c|
          case c.name
          when 'team'      then @my_color = c.value
          when 'worldsize' then world_size = c.value.to_f
          end
        end
        @map = BraveZealot::MapDiscrete.new(world_size, @my_color)
        
        bases do |r|
          obstacles do |r|
            flags do |r|
              othertanks do |r|
                # Initialize each of our tanks
                mytanks do |r|
                  r.mytanks.each do |t|
                    # Tell each agent about this Headquarters, its own +t+ index,
                    # and its initial state.
                    agent = Agent.new(self, t)
                    @agents[t.index] = agent
                  end
                  
                  @map.observe_mytanks(r)
                  
                  # BEGIN!
                  @agents.each_with_index do |a, i|
                    if $options.strategy
                      initial_state = :dummy
                    else
                      initial_state = $options.initial_state[i]
                    end
                    a.begin_state_loop(initial_state)
                  end
                  
                  # Periodically take PDF snapshots of the world
                  periodic_action(2, 60) { write_pdf }

                  # Update obstacles, flags, tanks, shots
                  periodic_update
                  
                  # Make strategic decisions every once in a while
                  periodic_action(1) { strategize } if $options.strategy
                end
              end
            end
          end
        end
      end
    end
    
    # Calls an action immediately and sets up a timer to periodically call the
    # action again. If +maximum+ is set to an integer value, then the action
    # will be called at most +maximum+ times.
    def periodic_action(period = 0.5, maximum = nil, &action)
      count = 0
      timer = EventMachine::PeriodicTimer.new(period, &(action_wrapper = proc do
        if maximum.nil? or (count += 1) <= maximum
          action.call
        else
          timer.cancel
        end
      end))
      # Do it immediately
      action_wrapper.call
      timer
    end
    
    def periodic_update(period = 0.3)
      # puts "periodic update"
      
      # Get up to 25 samples of the obstacles
      periodic_action(period * 1.5, 25) do
        obstacles
      end
      
      # Spread out our information gathering over time so we don't
      # constantly overwhelm the network.
      third = period / 3.0
      periodic_action(period) do
        sleep(third * 1.0) { flags                  }
        sleep(third * 2.0) { mytanks; othertanks    }
        sleep(third * 3.0) { shots                  }
      end
    end
    
    # Note: estimate_world_time may be non-continuous because @world_time is
    # updated sporadically.
    def estimate_world_time
      delta = Time.now - @clock
      @world_time + delta
    end
    
    def message_time(command)
      @message_times[command.to_sym] || 0.0
    end
    
    # Catch-all callback, called on EVERY message to EVERY tank
    def on_any(r)
      prev_clock = @clock
      @clock = Time.now
      @world_time = r.time
      @message_times[r.command.to_sym] = r.time
    end
    
    # If our most recent data is older than 'freshness', call command and get
    # more current info.  Otherwise, just assume our data is good enough and
    # call the passed-in block.
    def refresh(command, freshness = 0.0, &block)
      if (estimate_world_time - message_time(command)) > freshness
        # Note: Because global callbacks occur before local, on_* will
        # have a chance to update data before the following block.call
        ignore_arg = Proc.new { |r| block.call if block }

        #puts "refreshing #{command.to_s}"
        send(command, &ignore_arg)
      else
        #puts "calling secondary block for #{command.to_s}"
        block.call if block
      end
    end
    
    def sleep(time, &block)
      EventMachine::Timer.new(time, &block)
    end
    
    def on_bases(r)
      @map.bases = r.bases
      @my_base = @map.bases.find{ |b| b.color == @my_color }
    end
    
    def on_flags(r)
      @map.observe_flags(r)
    end

    def on_obstacles(r)
      @map.observe_obstacles(r)
    end

    def on_othertanks(r)
      @map.observe_othertanks(r)
    end
    
    def on_mytanks(r)
      @map.observe_mytanks(r)
      @agents.each do |a|
        if a.tank.status != "normal"
          a.funeral
        end
      end
    end

    def write_pdf
      @pdf_count ||= 0
      file = $options.pdf_file || "map.pdf"
      file.sub!(/\d*\./, "#{@pdf_count += 1}.")
      puts "\nWriting map to pdf: #{file}\n"
      distributions = []
      # @obstacles.each{ |o| o.coords.each{ |c| distributions << c.kalman_distribution } } if @obstacles
      # @map.mytanks.each{ |t| distributions << t.kalman_distribution }
      # @map.othertanks.each{ |t| distributions << t.kalman_distribution }
      paths = @agents.map{ |a| a.path }
      paths += @agents.select{ |a| !a.short_path.nil? }.map{ |a| a.short_path }
      @map.to_pdf(nil,
        :my_color      => my_color,
        :paths         => paths,
        :distributions => distributions
      ).save_as(file)
    end
    
    def install_signal_trap
      trap("INT") do
        if File.exist?($options.config_file)
          config = YAML.load(IO.read($options.config_file))
          $options.instance_variable_get("@table").merge! config
          write_pdf if $options.pdf_file
          if $options.state
            # Convert a comma-delimited list into states array
            states = state_list($options.state)
            # Update the agent states
            @agents.each_with_index { |a, i| a.state = states[i] }
          end
          disconnect if $options.abort_on_int
        else
          disconnect
        end
      end
    end
    
    def disconnect
      EventMachine::stop_event_loop
      exit(0)
    end
    
    
    
    # *** Game Objects and Pattern Matching Methods ***
    
    def get_flag(color)
      @map.flags.find{ |f| f.color == color }
    end
    
    def our_flag
      get_flag(@my_color)
    end
    
    def get_base(color)
      @map.bases.find{ |b| b.color == color }
    end
    
    def our_base
      get_base(@my_color)
    end
    
    def enemy_flags
      @map.flags.select{ |f| f.color != @my_color }
    end
    
    def enemy_colors
      enemy_flags.map{ |f| f.color }
    end
    
    # Return an array of bases that have associated enemy tanks
    # (Note: does not return unused bases)
    def enemy_bases
      colors = enemy_colors
      @map.bases.select{ |b| colors.include?(b.color) }
    end
    
    # Returns living tanks on a given team
    def tanks_on_team(color)
      if color == @my_color
        @map.mytanks.select{ |t| t.status == "normal" }
      else
        @map.othertanks.select{ |t| t.color == color && t.status == "normal" }
      end
    end
    
    def living_agents
      @agents.select{ |a| a.tank.status == "normal" }
    end
    
    # Returns true if the enemy's flag is in the game world
    def enemy_flag_exists?
      !(enemy_flags.empty?)
    end
    
    # Returns true if any of our tanks possesses an enemy flag
    def we_have_enemy_flag?
      @agents.any? do |a|
        a.tank.flag != "none" &&
        a.tank.flag != @my_color
      end
    end
    
    def enemy_has_our_flag?
      @map.othertanks.any? do |o|
        o.tank.flag == @my_color
      end
    end
    
    def our_flag_at_base?
      our_base.contains_point?(our_flag)
    end
    
    # Returns the number of tanks defending a base
    def base_defense_score(color, radius = 50)
      base = get_base(color)
      tanks_on_team(color).inject(0) do |sum, tank|
        sum + (base.center.vector_to(tank).length < radius ? 1 : 0)
      end
    end
    
    def undefended_enemy_bases(radius = 50)
      enemy_bases.select{ |b| base_defense_score(b.color, radius) == 0 }
    end
    
    # Return an array of the agents nearest to +coord+, in order of nearest to farthest
    def agents_nearest(coord, count)
      @agents.sort_by{ |a| coord.vector_to(a.tank).length }[0...count]
    end
    
    # Array of enemy tanks within +radius+ of +coord+
    def enemies_nearby(coord, enemy_color, radius = 350)
      tanks_on_team(enemy_color).select{ |t| coord.vector_to(t).length < radius }
    end
    
    # Array of enemy tanks within +radians+ of coord & theta
    def enemies_ahead(coord, theta, enemy_color, radians = Math::PI/4)
      direction = Vector.angle(theta)
      tanks_on_team(enemy_color).select do |t|
        direction.angle_diff(coord.vector_to(t)).abs < radians
      end
    end
    
    
    # *** The General's Quarters, Strategy, etc. ***
    
    def kill_if_enemy_ahead(agent, enemy_color)
      Proc.new {
        nearby = enemies_nearby(agent.tank, enemy_color, 50)
        ahead  = enemies_ahead(agent.tank, agent.tank.angle, enemy_color, Math::PI/4)
        target = nearby.first || ahead.first
        agent.set_state(:assassin, :target => target) unless target.nil?
      }
    end
    
    def strategize
      flags = enemy_flags()
      if flags.size > 0
        # Choose one enemy for now
        enemy_color = flags.first.color
        enemy_flag = get_flag(enemy_color)
        enemies = tanks_on_team(enemy_color)
        
        # Only strategize with living agents
        ags = living_agents
        # puts "HQ: I have #{ags.size} agents"
        
        if enemies.size > 0
          puts "Targetting enemy: #{enemies.first.callsign}"
          ags.first.set_state(:assassin, :target_tank => enemies.first)
        end
        
        # case ags.size
        # when 0 then
        #   puts "Ah! We're dead. No agents left."
        # when 1 then
        #   puts "Only one agent left... Kamakaze!!"
        #   ags[0].set_state(:seek, :goal => enemy_flag)
        #   ags[0].periodically(0.5) { ags[0].shoot }
        # when 2 then
        #   puts "Two agents left... one defense one offense"
        #   ags = agents_nearest(enemy_flag, 2)
        #   ags[0].set_state(:seek, :goal => enemy_flag,
        #                    :abort => kill_if_enemy_ahead(ags[0], enemy_color))
        #   ags[1].set_state(:seek, :goal => our_flag)
        # else
        #   puts "I don't know what to do with 3 or more agents right now"
        # end
        
        # @map.flags.each do |flag|
        #   score = base_defense_score(flag.color)
        #   puts "Team: #{flag.color}, defense score: #{score}"
        # end
      else
        puts "No enemies on map"
        # @base_target ||= @map.bases.select{ |b| b.color != @my_color }.randomly_pick(1).first
        # living_agents.each{ |a| a.set_state(:seek, :goal => @base_target.center) }
      end
    end
    
  end
end
