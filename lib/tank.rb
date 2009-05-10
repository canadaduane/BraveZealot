module BraveZealot

  class Tank
    # tank :: BraveZealot::Communicator::Tank -> Data object
    attr_accessor :tank
    attr_accessor :goal
    attr_accessor :mode
    
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
            shoot()
            
            case mode
            when :accel_once then
              sleep(1.5) do
                mode = :move
              end
              mode = :accel
            when :move then
              curr_speed = Math.sqrt(vx**2 + vy**2)
              # Check if we've hit something
              mode = :turn if curr_speed < 24.5
            when :turn then
              # Turn and then go straight again
              angvel(1.0) do
                speed(-0.1)
                sleep(2.0) do
                  speed 1.0
                  angvel(0.0)
                  mode = :accel_once
                end
              end
            end # case
            
          end # PeriodicTimer
        end # sleep
      end # speed
    end # start
    
  end

  class SmartTank < Tank
    
    def start
      EventMachine::PeriodicTimer.new(0.1) do
        refresh(0.1) do
          shoot()
          if @goal
            #puts "x: #{@tank.x}, y: #{@tank.y}, angle: #{angle}"
            
            move = @goal.suggestMove(@tank.x, @tank.y, angle)
            #puts "Move: #{move.inspect}"
            speed move.speed
            angvel move.angvel
          end
        end
      end
    end
    
  end
end
