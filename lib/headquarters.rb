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
                    initial_state = $options.initial_state[i]
                    a.begin_state_loop(initial_state)
                  end
                  
                  # Periodically take PDF snapshots of the world
                  periodic_action(2, 30) { write_pdf }

                  # Update obstacles, flags, tanks, shots
                  periodic_update
                  
                  # Make strategic decisions every once in a while
                  periodic_action(5) { strategize }
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
    
    def on_flags(r)
      @map.flags = r.flags
    end
    
    def on_bases(r)
      @map.bases = r.bases
      @my_base = @map.bases.find{ |b| b.color == @my_color }
    end
    
    def on_obstacles(r)
      @map.observe_obstacles(r)
    end

    def on_othertanks(r)
      # @map.othertanks = r.othertanks
      @map.observe_othertanks(r)
    end
    
    def on_mytanks(r)
      @map.observe_mytanks(r)
      #@map.mytanks = r.mytanks
      #r.mytanks.each do |t|
      #  @agents[t.index].tank = t if @agents.size > t.index
      #end
    end

    def disconnect
      EventMachine::stop_event_loop
      exit(0)
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
    
    def enemy_bases
      @map.bases.select{ |b| b.color != @my_color }
    end
    
    def tanks_on_team(color)
      if color == @my_color
        @map.mytanks
      else
        @map.othertanks.select{ |t| t.color == color }
      end
    end
    
    # Returns true if the enemy's flag is in the game world
    def enemy_flag_exists?
      !(enemy_flags.empty?)
    end
    
    # Returns true if any of our tanks possesses an enemy flag
    def we_have_enemy_flag?
      @agents.any? do |t|
        #puts "t.tank.flag = #{t.tank.flag}"
        t.tank.flag != "none" &&
        t.tank.flag != @my_color
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
    
    def undefended_enemy_bases
      enemy_bases.select{ |b| base_defense_score(b.color) == 0 }
    end
    
    # *** The General's Quarters, Strategy, etc. ***
    
    def strategize
      @map.flags.each do |flag|
        score = base_defense_score(flag.color)
        puts "Team: #{flag.color}, defense score: #{score}"
      end
    end
    
  end
end
