bzrequire 'lib/communicator'
bzrequire 'lib/map_discrete'
bzrequire 'lib/agent'

module BraveZealot
  class Headquarters < Communicator
    attr_reader :map, :my_color, :my_base, :mytanks_time, :other_tanks
    
    class MissingData < Exception; end
    
    def start
      @agents = []                # Current BraveZealot::Agent objects
      @world_time = 0.0           # Last communicated world time
      @message_times = {}         # Last time we received a message (in Time.now units)
      @other_tanks = []
      
      # Gather initial world data... which team are we?  how big is the map?
      constants do |r|
        world_size = nil
        r.constants.each do |c|
          case c.name
          when 'team'      then @my_color = c.value
          when 'worldsize' then world_size = c.value.to_f
          end
        end
        @map = BraveZealot::MapDiscrete.new(world_size)
        
        refresh(:bases) do
          refresh(:obstacles) do
            refresh(:flags) do
              refresh(:othertanks) do
                #Spit out a map
                f = File.new($options.gnuplot_file, 'w')
                f.write(@map.to_gnuplot)
                f.close

                # Initialize each of our tanks
                mytanks do |r|
                  r.mytanks.each do |t|
                    agent = Agent.new(self, t, $options.initial_state[t.index])
                    @agents[t.index] = agent
                  end
                end
              end
            end
          end
        end
      end
      
      mobilize
    end
    
    def mobilize
      EventMachine::PeriodicTimer.new(0.5) do
        refresh(:flags, 0.2) do
          if flag_possession?
            @agents.each_with_index do |t, i|
              if t.mode != :home
                puts "changing tank #{i} to goal :home"
                t.goal = create_home_base_goal
                t.mode = :home
              end
            end
          else
            @agents.each_with_index do |t, i|
              if enemy_flag_exists?
                puts "changing tank #{i} to goal :capture_flag"
                t.goal = create_flag_goal
                t.mode = :capture_flag
              end
            end
          end
        end
      end
    end
    
    def enemy_flags
      @map.flags.select{ |f| f.color != @my_color }
    end
    
    # Returns true if the enemy's flag is in the game world
    def enemy_flag_exists?
      !(enemy_flags.empty?)
    end
    
    # Returns true if any of our tanks possesses an enemy flag
    def flag_possession?
      @agents.any? do |t|
        #puts "t.tank.flag = #{t.tank.flag}"
        t.tank.flag != "none" &&
        t.tank.flag != @my_color
      end
    end
    
    def create_flag_goal
      flag_goal = PfGroup.new
      flag_goal.add_obstacles(@map.obstacles)
      refresh(:flags, 0.5) do
        enemy_flags = @map.flags.select{ |f| f.color != @my_color }
        puts "adding flag goal at #{enemy_flags.first.x}, #{enemy_flags.first.y}"
        flag_goal.add_goal(enemy_flags.first.x, enemy_flags.first.y, @map.size) unless enemy_flags.empty?
      end
      flag_goal
    end
    
    def create_home_base_goal
      base_goal = PfGroup.new
      base_goal.add_obstacles(@map.obstacles)
      base_goal.add_goal(@my_base.center.x, @my_base.center.y, @map.size)
      base_goal
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
      @clock = Time.now
      @world_time = r.time
      @message_times[r.command.to_sym] = r.time
      #p r; puts
    end
    
    # If our most recent data is older than 'freshness', call command and get
    # more current info.  Otherwise, just assume our data is good enough and
    # call the passed-in block.
    def refresh(command, freshness = 0.0, &block)
      if (estimate_world_time - message_time(command)) > freshness
        # Note: Because global callbacks occur before local, on_* will
        # have a chance to update data before the following block.call
        ignore_arg = Proc.new { |r| block.call if block }
        send(command, &ignore_arg)
      else
        block.call if block
      end
    end
    
    def on_mytanks(r)
      r.mytanks.each do |t|
        @agents[t.index].tank = t if @agents.size > t.index
      end
    end
    
    def on_flags(r)
      
      @map.flags = r.flags
    end
    
    def on_bases(r)
      @map.bases = r.bases
      @my_base = @map.bases.find{ |b| b.color == @my_color }
    end
    
    def on_obstacles(r)
      @map.obstacles = r.obstacles
    end

    def on_othertanks(r)
      r.othertanks.each do |ot|
        puts "I saw an enemy tank at #{ot.to_coord.inspect} or #{@map.chunk_at_point(ot.x,ot.y).to_coord.inspect} which will be penalized"
        @map.chunk_at_point(ot.x,ot.y).penalty=2.0
      end
      other_tanks = r.othertanks
    end
  end
end
