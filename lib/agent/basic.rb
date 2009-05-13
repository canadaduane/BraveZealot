module BraveZealot
  module Agent
    class Basic
      # tank :: BraveZealot::Tank -> Data object
      # goal :: PfGroup -> Potential field guidance to goal
      # mode :: Symbol  -> :capture_flag, :home
    
      attr_accessor :tank, :goal, :mode
    
      # Expects a Communicator::Tank struct for init
      def initialize(hq, tank)
        @hq, @tank = hq, tank
        start
      end
    
      def refresh(freshness, &block)
        @hq.refresh(:mytanks, freshness, &block)
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
  end
end
