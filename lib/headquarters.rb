bzrequire 'lib/communicator'
bzrequire 'lib/tank'
bzrequire 'lib/map'

module BraveZealot
  class Headquarters < Communicator
    attr_reader :mytanks_time
    
    def start
      @bindings = {
        :hit => []
      }
      @tanks = {}                 # Current BraveZealot::Tank objects
      @previous_tank_data = {}    # Communicator::Tank data from previous iteration
      @world_time = 0.0           # Last communicated world time
      @last_message_time = 0.0    # Last time we received a message (in Time.now units)
      @last_mytanks_time = 0.0    # Last time we received a mytanks message
      
      constants do |r|
        r.constants.each do |c|
          case c.name
          when 'team'      then @team = c.value
          when 'worldsize' then @world_size = c.value.to_f
          end
        end
        puts "Team: #{@team}"
        puts "World size: #{@world_size}"
        
        @map = BraveZealot::Map.new(@team, @world_size)
        
        obstacles do |r|
          r.obstacles.each do |o|
            @map.addObstacle(o.coords)
          end
          
          flags do |r|
            r.flags.each do |f|
              if f.color != @team
                @map.addFlag(f)
              end
              
              # group = PfGroup.new
              # group.addMapFields(@map)
          
              File.open("map.gpi", "w") do |f|
                f.write @map.to_gnuplot
              end
            end
          end
        end
      end
      
      
      # Initialize each of our tanks
      mytanks do |r|
        r.mytanks.each do |t|
          if ARGV[0] == "dummy"
            @tanks[t.index] = BraveZealot::DummyTank.new(self, t)
          else
            @tanks[t.index] = BraveZealot::SmartTank.new(self, t)
          end
        end
      end
    end
    
    def timer(slice)
      # refresh_mytanks(0.1) do
      #   @tanks.each do |index, tank|
      #     if tank.vx != @previous_tank_data[index].vx ||
      #        tank.vy != @previous_tank_data[index].vy
      #   end
      # end
    end
    
    # Note: current_time may be non-continuous because @world_time is updated sporadically
    def current_time
      delta = Time.now - @last_message_time
      @world_time + delta
    end
    
    # Catch-all callback, called on EVERY message to EVERY tank
    def on_any(r)
      @last_message_time = Time.now
      @world_time = r.time
      p r; puts
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
          @previous_tank_data[t.index] = @tanks[t.index].tank
          @tanks[t.index].tank = t
        end
      end
    end
  end
end
