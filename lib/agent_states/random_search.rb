
module BraveZealot
  module RandomSearchStates
    def rsr
      # rsr_stochastics
      hq.periodic_action(1.0, 1) { rsr_choose_destination }
    end
    
    def rsr_deviation
      case rand(5)
      when 0 then -1
      when 4 then 1
      else 0
      end
    end
    
    def rsr_choose_destination
      @goal = hq.map.random_spot || Coord.new(0, 0)
      puts "Random destination chosen: #{@goal.x}, #{@goal.y}"
      puts "Current location: #{@tank.x}, #{@tank.y}"
      @path = hq.map.search(@tank, @goal)
      # puts "RSR Path Before: #{@path.inspect}"
      # hq.map.randomize_path!(@path)
      # puts "RSR Path After: #{@path.inspect}"
      push_next_state(:seek_arrived, :rsr_choose_destination)
      transition(:rsr_choose_destination, :seek)
    end
    
  end
end