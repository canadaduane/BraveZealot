module BraveZealot
  module RandomSearchStates
    def rsr
      # rsr_stochastics
      rsr_choose_destination
    end
    
    def rsr_stochastics
      @hq.periodic_action(1.0) do
        # puts "vx: #{@tank.vx}, vy: #{@tank.vy}, speed: #{@tank.speed}"
        if @pause_smart_angvel
          # Get out of our random deviation
          @pause_smart_angvel = false
        elsif @tank.speed >= 18 and rand(10) > 5
          # Cause a random deviation
          @pause_smart_angvel = true
          vel = case rand(2)
          when 0 then -0.5
          when 1 then  0.5
          end
          puts "New angvel: #{vel}"
          angvel(vel)
          speed(1.0)
        end
      end
    end
    
    def rsr_choose_destination
      @goal = hq.map.random_spot || Coord.new(0, 0)
      puts "Random destination chosen: #{@goal.x}, #{@goal.y}"
      @state = :smart
      push_next_state(:smart, :rsr_choose_destination)
    end
  end
end