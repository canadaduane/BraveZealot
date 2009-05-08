bzrequire 'lib/communicator'
bzrequire 'lib/tank'

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
      
      # Initialize each of our tanks
      mytanks do |r|
        r.mytanks.each do |t|
          @tanks[t.index] = BraveZealot::DummyTank.new(self, t)
        end
        puts
      end
    end
    
    def timer
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
        mytanks { |r| block.call }
      else
        block.call
      end
    end
    
    def on_mytanks(r)
      @last_mytanks_time = r.time
      r.mytanks.each do |t|
        @previous_tank_data[t.index] = @tanks[t.index].tank
        @tanks[t.index].tank = t
      end
    end
  end
end
