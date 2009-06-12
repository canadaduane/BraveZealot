module BraveZealot
  module RandomSearchStates
    def rsr
      rsr_choose_destination
    end
    
    def rsr_choose_destination
      @goal = hq.map.random_spot || Coord.new(0, 0)
      puts "Random destination chosen: #{@goal.x}, #{@goal.y}"
      @state = :smart
      push_next_state(:smart, :rsr_choose_destination)
    end
  end
end