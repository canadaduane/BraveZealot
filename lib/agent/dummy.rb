bzrequire 'lib/agent/basic'

module BraveZealot
  module Agent
    class Dummy < Basic
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
  end
end

