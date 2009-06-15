require 'rubystats/normal_distribution'

module BraveZealot
  module DisperseStates
    def disperse
      @disperse_center ||= Coord.new(@tank.x, @tank.y)
      @disperse_radius ||= 400
      
      normal = Rubystats::NormalDistribution.new(@disperse_radius, @disperse_radius/3.0)
      begin
        angle = rand * Math::PI * 2
        distance = normal.rng
        x = @disperse_center.x + Math::cos(angle) * distance
        y = @disperse_center.y + Math::sin(angle) * distance
        @goal = Coord.new(x, y)
      end while !hq.map.in_world_space?(@goal)
      
      puts "agent #{@tank.index} dispersing to #{@goal.x}, #{@goal.y}"
      
      push_next_state(:seek_done, :disperse_done)
      transition(:disperse, :seek)
    end
    
    def disperse_done
      transition(:disperse_done, :wait)
    end
  end
end