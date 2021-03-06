module BraveZealot
  module ShadowMethods
    def shadows(map, freshness = 1.0)
      @shadows_time ||= Time.mktime(0).to_f

      now = Time.now().to_f
      if (now - @shadows_time) > freshness then
        @shadows_time = now
        if @shadows_position.nil? or @shadows_position.vector_to(self).length > 20.0 then
          @shadows_position = Coord.new(x,y)
          puts "re-calculating shadows for enemy tank #{callsign}"
          if @shadows.nil? then
            @shadows = Astar.new(map.side_length, map.side_length, 0.0)
          else
            @shadows.clear
          end
          
          map.obstacles.each do |ob|
            #find which two coords make up the max/min angle with where i am 
            min = nil
            min_ang = nil
            max = nil
            max_ang = nil
            ob.coords.each do |c|
              #ang = Math::atan2(c.y -self.y, c.x - self.x)
              ang = vector_to(c).angle
              if min.nil? then
                min = c
                min_ang = ang
              elsif min_ang > ang then
                min = c
                min_ang = ang
              end

              if max.nil? then
                max = c
                max_ang = ang
              elsif max_ang < ang then
                max = c
                max_ang = ang
              end
            end
            
            #now find a projection of the two points to make up 4 total points
            v = self.vector_to(min)
            projected_min = Coord.new(min.x + (map.world_size * v.x), min.y + (map.world_size * v.y))
            v = self.vector_to(max)
            projected_max = Coord.new(max.x + (map.world_size * v.x), max.y + (map.world_size * v.y))

            #draw the shaded region onto the astar map
            @shadows.quad([min,max,projected_min,projected_max].map{ |c| map.world_to_array_coordinates(c.x,c.y)}, -5.0)
          end
        end
      end
    
      @shadows
    end
  end
end