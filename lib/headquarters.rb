bzrequire 'lib/communicator'
bzrequire 'lib/tank'
bzrequire 'lib/map'
bzrequire 'lib/command'

module BraveZealot
  class Headquarters < Communicator
    attr_reader :mytanks_time
    attr_reader :map
    attr_reader :team_color
    attr_reader :our_base

    def start
      @bindings = {
        :hit => []
      }
      @tanks = {}                 # Current BraveZealot::Tank objects
      @world_time = 0.0           # Last communicated world time
      @last_message_time = 0.0    # Last time we received a message (in Time.now units)
      @last_mytanks_time = 0.0    # Last time we received a mytanks message
      @obstacles = []
      @our_base = nil
      @enemy_bases = []
      
      constants do |r|
        r.constants.each do |c|
          case c.name
          when 'team'      then @team_color = c.value
          when 'worldsize' then @world_size = c.value.to_f
          end
        end
        #puts "Team: #{@team_color}"
        #puts "World size: #{@world_size}"
        
        @map = BraveZealot::Map.new(@team_color, @world_size)
        
        # Get base information and set @our_base
        bases do |r|
          r.bases.each do |b|
            if b.color == @team_color
              @our_base = b
            else
              @enemy_bases << b
            end
          end
          #puts "Our Base: #{@our_base.inspect}"
          #puts "Enemy Bases: #{@enemy_bases.inspect}"
        end

        @command = Command.new(self)
        
        obstacles do |r|
          @obstacles = r.obstacles
          
          r.obstacles.each do |o|
            @map.addObstacle(o.coords)
          end
          
          flags do |r|
            r.flags.each do |f|
              if f.color != @team_color
                @map.addFlag(f)
              end
            end

            #generate potential field plots
            flag_goal = @command.create_flag_goal
            base_goal = @command.create_home_base_goal

            flag_file = File.new('flag.gpi', 'w')
            flag_file.write(@map.to_gnuplot(flag_goal))
            flag_file.close

            base_file = File.new('base.gpi','w')
            base_file.write(@map.to_gnuplot(base_goal))
            base_file.close
            
            # Initialize each of our tanks
            mytanks do |r|
              r.mytanks.each do |t|
                tank =
                  case $options.brain
                  when 'dummy' then BraveZealot::DummyTank.new(self, t)
                  when 'smart' then BraveZealot::SmartTank.new(self, t)
                  end
                tank.goal = @command.create_flag_goal
                tank.mode = Command::GO_TO_FLAG
                @tanks[tank.index] = tank
              end
            end
            
          end
        end
      end
      
      if $options.brain == 'smart' then
        EventMachine::PeriodicTimer.new(0.5) do
          if flag_possession?
            @tanks.values.each do |t|
              if t.mode != Command::GO_HOME then
                puts "changing tank to goal GO_HOME"
                t.goal = @command.create_home_base_goal
                t.mode = Command::GO_HOME
              end
            end
          else
            @tanks.values.each do |t|
              #if t.mode != Command::GO_TO_FLAG then
                puts "changing tank to goal GO_TO_FLAG"
                t.goal = @command.create_flag_goal
                t.mode = Command::GO_TO_FLAG
              #end
            end
          end
        end
      end
      
    end
    
    def flag_possession?
      @tanks.values.any? do |t|
        #puts "t.tank.flag = #{t.tank.flag}"
        t.tank.flag != "none" &&
        t.tank.flag != @team_color
      end
    end

    def get_obstacles
      @obstacles
    end
    
    # Note: current_time may be non-continuous because @world_time is updated
    # sporadically.
    def current_time
      delta = Time.now - @last_message_time
      @world_time + delta
    end
    
    # Catch-all callback, called on EVERY message to EVERY tank
    def on_any(r)
      @last_message_time = Time.now
      @world_time = r.time
      #p r; puts
    end
    
    # Tanks will call 'bind' to notify headquarters that it wants info whenever
    # a specific event (such as hitting a wall) occurs.
    def bind(event, &block)
      if @bindings.keys.include?(event)
        @bindings[event] << block
      else
        raise "Unknown event: #{event}"
      end
    end
    
    # If our most recent data is older than 'freshness', call mytanks and get
    # more current info.  Otherwise, just assume our data is good enough and
    # call the passed-in block.
    def refresh_mytanks(freshness, &block)
      if (current_time - @last_mytanks_time) > freshness
        # Note: Because global callbacks occur before local, on_mytanks will
        # have a chance to update all tank data before the following block.call
        mytanks { |r| block.call if block }
      else
        block.call if block
      end
    end
    
    def on_mytanks(r)
      @last_mytanks_time = r.time
      r.mytanks.each do |t|
        if @tanks[t.index]
          @tanks[t.index].tank = t
        end
      end
    end
  end
end
