module BraveZealot

  class Tank
    # Expects a Communicator::Tank struct for init
    def initialize(hq, tank)
      @hq, @tank = hq, tank
      start
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
      speed 1.0
    end
    
    def timer(slice)
      puts "slice: #{slice}"
    end
  end

end
