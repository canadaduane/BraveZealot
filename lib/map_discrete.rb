bzrequire 'lib/map'
bzrequire 'lib/astar/astar'

module BraveZealot
  class MapDiscrete < Map
    attr_reader :map
    
    def initialize(world_size, granularity = 2)
      super(world_size)
      @granularity = granularity
      @side_length = (@world_size / @granularity).ceil
      @map = Array.new(@side_length ** 2, 0)
      @astar = Astar.new(@map, @side_length)
    end
    
    # the coordinates generated from this put the item directly in the center of
    # the grid as it would translate into world coordinates
    # so grid 0,0 would translate to -390, 390 assuming each grid was 20 meters wide
    def array_to_world_coordinates(col, row)
      return (world_x_min + (@granularity / 2) + (col * @granularity)), 
             (world_y_max - (@granularity / 2) - (row * @granularity))
    end
    
    # returns column, row
    def world_to_array_coordinates(x, y)
      return ((x - world_x_min) / @granularity).to_i, 
             ((world_y_max - y) / @granularity).to_i
    end
    
    def coord_to_index(x, y)
      y * @side_length + x
    end
    
    def obstacles=(obstacles)
      @obstacles = obstacles
      # instead of asking each location if its center is in any of
      # of the obstacles, we can ask each obstacle which locations it
      # blocks
      obstacles.each do |o|
        o.locations_blocked(self).each do |c|
          @map[coord_to_index(c.x,c.y)] = -1
        end
      end
    end
    
    def search(start, goal)
      s = world_to_array_coordinates(start.x, start.y)
      g = world_to_array_coordinates(goal.x, goal.y)
      @astar.search(s[0], s[1], g[0], g[1])
    end
    
    def to_gnuplot
      str = super do
        str = ""
        #puts "Looping from 1..#{@side_length}"
        #for idx in 1..@side_length 
        #  str << "set arrow from " +
        #        "#{idx*@granularity - world_x_max},#{@side_length*@granularity - world_y_max} to " +
        #        "#{idx*@granularity},#{@side_length*@granularity} nohead lt 1\n"
        #  str << "set arrow from " +
        #        "#{-1*@side_length*@granularity - world_x_max},#{idx*@granularity - world_y_max} to " +
        #        "#{@side_length*@granularity},#{idx*@granularity} nohead lt 1\n"
        #end
        #str
        for row in 0..@side_length
          for col in 0..@side_length
            if @map[coord_to_index(col, row)] == -1
              x,y = array_to_world_coordinates(col,row)
              str << "set arrow from " +
                  "#{x - (@granularity/2)},#{y - (@granularity/2)} to " +
                  "#{x + (@granularity/2)},#{y + (@granularity/2)} nohead lt 3\n" 
            end
          end
        end
        str
      end
      str
    end
    
  end

end