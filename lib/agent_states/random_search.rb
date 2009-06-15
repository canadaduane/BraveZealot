module BraveZealot
  module RandomSearchStates
    def rsr
      # rsr_stochastics
      periodically(0.5) do
        if hq.enemy_flags.size > 0
          enemy_color = hq.enemy_flags.first.color
          ahead = hq.enemies_ahead(@tank, @tank.angle, enemy_color, Math::PI/8)
          if ahead.size > 0 and @tank.vector_to(ahead.first).length < 200
            periodically(0.1, 3){ shoot }
          end
        end
      end
      rsr_choose_destination
    end
    
    def rsr_choose_destination
      @goal = hq.map.random_spot || Coord.new(0, 0)
      puts "Random destination chosen: #{@goal.x}, #{@goal.y}"
      puts "Current location: #{@tank.x}, #{@tank.y}"
      @path = hq.map.search(@tank, @goal)
      # puts "RSR Path Before: #{@path.inspect}"
      # hq.map.randomize_path!(@path)
      # puts "RSR Path After: #{@path.inspect}"
      push_next_state(:seek_done, :rsr_choose_destination)
      transition(:rsr_choose_destination, :seek)
    end
    
  end
end