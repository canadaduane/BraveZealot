module BraveZealot

  class Tank
    # tank :: BraveZealot::Communicator::Tank -> Data object
    attr_accessor :tank
    
    # Expects a Communicator::Tank struct for init
    def initialize(hq, tank)
      @hq, @tank = hq, tank
      start
    end
    
    def refresh(freshness, &block)
      @hq.refresh_mytanks(freshness, &block)
    end
    
    def sleep(time, &block)
      EventMachine::Timer.new(time, &block)
    end
    
    def bind(*args, &block)
      hq.bind(*args, &block)
    end
    
    def angvel(value = nil, &block)
      value.nil? ? @tank.send(:angvel) : @hq.send(:angvel, @tank.index, value, &block)
    end
    
    def method_missing(m, *args, &block)
      if @tank.respond_to? m
        @tank.send(m, *args, &block)
      elsif @hq.respond_to? m
        @hq.send(m, @tank.index, *args, &block)
      else
        raise NameError
      end
    end
  end
  
  class DummyTank < Tank
    
    def start
      speed(1.0) do
        sleep(1.0) do
          mode = :move
          EventMachine::PeriodicTimer.new(0.2) do
            refresh(0.2)
            
            case mode
            when :move then
              curr_speed = Math.sqrt(vx**2 + vy**2)
              # Check if we've hit something
              mode = :turn if curr_speed < 0.95
            when :turn then
              # Turn and then go straight again
              angvel(1.0) do
                sleep(0.5) do
                  mode = :move
                end
              end
            end # case
            
          end # PeriodicTimer
        end # sleep
      end # speed
    end # start
    
  end

end
