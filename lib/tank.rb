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
      @hq.refresh_mytanks(&block)
    end
    
    def sleep(time, &block)
      EventMachine::Timer.new(time, &block)
    end
    
    def bind(*args, &block)
      hq.bind(*args, &block)
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
      speed(1.0)
      bind(:hit) do
        speed(-0.05)
        start_angle = angle
        turn60 = Proc.new do
          refresh(0.2) do
            angvel(1.0) do
              sleep(0.1) do
                if abs(start_angle - angle) < 60
                  # Keep turning
                  turn60.call
                else
                  # We've turned enough, now go straight
                  angvel(0.0)
                  speed(1.0)
                end
              end
            end
          end
        end
        
        turn60.call
      end
    end
  end

end
