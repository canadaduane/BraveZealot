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
                      initial_state = :wait
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
    
    # Returns the number of tanks on a team that are defending a specific area
    def defense_score(coord, color, radius = 50)
      tanks_on_team(color).inject(0) do |sum, tank|
        sum + (coord.vector_to(tank).length < radius ? 1 : 0)
      end
    end
    
    # Return an array of the agents nearest to +coord+, in order of nearest to farthest
    def agents_nearest(coord, count)
      living_agents.sort_by{ |a| coord.vector_to(a.tank).length }[0...count]
    end
    
    def enemies_nearest(coord, enemy_color, count)
      tanks_on_team(enemy_color).sort_by{ |t| coord.vector_to(t).length }[0...count]
    end
    
    # Array of enemy tanks within +radius+ of +coord+
    def tanks_nearby(coord, color, radius = 350)
      tanks_on_team(color).select{ |t| coord.vector_to(t).length < radius }
    end
    
    # Array of enemy tanks within +radians+ of coord & theta
    def tanks_ahead(coord, theta, color, radians = Math::PI/4)
      direction = Vector.angle(theta)
      tanks_on_team(color).select do |t|
        direction.angle_diff(coord.vector_to(t)).abs < radians
      end
    end
    
    
    # *** The General's Quarters, Strategy, etc. ***
    
    def kill_if_enemy_ahead(agent, enemy_color)
      Proc.new {
        nearby = tanks_nearby(agent.tank, enemy_color, 50)
        ahead  = tanks_ahead(agent.tank, agent.tank.angle, enemy_color, Math::PI/6)
        target = nearby.first || ahead.first
        if target and @tank.vector_to(target).length < 375
          agent.set_state(:assassinate, :target_tank => target)
        end
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
        puts "HQ: I have #{ags.size} agents"
        # p ags.map{ |a| a.assignment }
        
        our_defense_score = defense_score(our_flag, @my_color, 50)
        
        # If we're all crowded around our base, move out
        if @grp_crowded.nil? and our_defense_score == ags.size
          puts "Flag area is crowded"
          @grp_crowded = ags.select{ |a| a.idle? }
          @grp_crowded.each do |agent|
            agent.set_state(:disperse)
          end
          EM::Timer.new(10){ @dispersed = true }
        end
        
        if @dispersed and @grp_middle.nil?
          others = ags.
            reject{ |a| (@grp_defense || []).include? a}.
            reject{ |a| (@grp_offense || []).include? a}
          if others.size > 2
            @grp_kill = others[0..1]
            @grp_middle = others[2..-1]
          else
            @grp_kill = []
            @grp_middle = others
          end
          # Assign remaining to geurilla tactics
          @grp_middle.each do |agent|
            agent.set_state(:rsr)
          end
          @grp_kill.each do |agent|
            if enemy = enemies_nearest(agent.tank, enemy_color, 1).first
              agent.push_next_state(:assassinate_done, :done)
              agent.push_next_state(:seek_done, :done)
              agent.set_state(:assassinate, :target_tank => enemy)
            end
          end
          EM::Timer.new(30){ @grp_middle = nil }
        end
        
        if @grp_defense.nil? and ags.size > 2 and our_defense_score == 0
          puts "No one is defending our flag"
          @grp_defense = agents_nearest(our_flag, ags.size > 3 ? 2 : 1)
          @grp_defense.each do |agent|
            agent.set_state(:defend, :goal => our_flag)
          end
          EM::Timer.new(20){ @grp_defend = nil }
        end
        
        # If enemy's flag is mostly undefended, send closest 2 agents to grab it
        if  (@grp_offense.nil? or @grp_offense.size < 2) and
            defense_score(enemy_flag, enemy_color, 150) <= 1
          puts "Enemy flag is mostly undefended"
          @grp_offense = agents_nearest(enemy_flag, 2)
          @grp_offense.each do |agent|
            agent.set_state(:capture_flag)
          end
        elsif @grp_offense and !@grp_offense.all?{ |a| ags.include?(a) }
          @grp_offense.delete_if do |agent|
            !ags.include?(agent)
          end
        end
          
        # if enemies.size > 0
        #   puts "Targetting enemy: #{enemies.first.callsign}"
        #   ags.first.push_next_state(:assassinate_done, :done)
        #   ags.first.push_next_state(:seek_done, :done)
        #   ags.first.set_state(:assassinate, :target_tank => enemies.first)
        # else
        #   puts "No enemies to target (#{@map.othertanks.inspect})"
        # end
        
      else
        puts "No enemies on map"
      end
    end
    
  end
end
