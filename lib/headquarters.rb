bzrequire 'lib/communicator'
bzrequire 'lib/map_discrete'
bzrequire 'lib/agent'
bzrequire 'lib/pf_group'

module BraveZealot
  class Headquarters < Communicator
    attr_reader :map, :my_color, :my_base, :mytanks_time
    
    class MissingData < Exception; end
    
    def start
      @agents = []                # Current BraveZealot::Agent objects
      @world_time = 0.0           # Last communicated world time
      @message_times = {}         # Last time we received a message (in Time.now units)
      
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
        
        bases do |r|
          obstacles do |r|
            flags do |r|
              othertanks do |r|

                #f = File.new($options.gnuplot_file, 'w')
                #f.write(@map.to_gnuplot)
                #f.close

                # Initialize each of our tanks
                mytanks do |r|
                  r.mytanks.each do |t|
                    # Tell each agent about this Headquarters, its own +t+ index, and its initial state
                    agent = Agent.new(self, t, $options.initial_state[t.index])
                    @agents[t.index] = agent
                  end
                end
              end
            end
          end
        end
      end
      periodic_update
    end
    
    def periodic_update
      # Spread out our information gathering over time so we don't
      # constantly overwhelm the network.
      EventMachine::PeriodicTimer.new(0.4) do
        sleep(0.1) { flags      }
        sleep(0.2) { mytanks    }
        sleep(0.3) { othertanks }
        sleep(0.4) { shots      }
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
        flag_goal.add_goal(enemy_flags.first.x, enemy_flags.first.y, @map.world_size) unless enemy_flags.empty?
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
    
    def sleep(time, &block)
      EventMachine::Timer.new(time, &block)
    end
    
    def on_mytanks(r)
      @map.mytanks = r.mytanks
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
      @map.othertanks = r.othertanks
    end
  end
end
