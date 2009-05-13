bzrequire 'lib/agent/basic'

module BraveZealot
  module Agent
    class Smart < Basic
      def start
        EventMachine::PeriodicTimer.new($options.refresh) do
          refresh($options.refresh) do
            #shoot() #shooting mostly ends up killing ourselves, so lets avoid that
            if @goal
              #puts "x: #{@tank.x}, y: #{@tank.y}, angle: #{angle}"
            
              move = @goal.suggest_move(@tank.x, @tank.y, angle)
              #puts "Move: #{move.inspect}"
              speed move.speed
              angvel move.angvel
            end
          end
        end
      end
    
    end
  end
end
