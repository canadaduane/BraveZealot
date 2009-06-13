bzrequire 'lib/map'
bzrequire 'lib/astar/astar'

module BraveZealot
  class MapDiscrete < Map
    attr_reader :astar
    
    def initialize(world_size, my_color, granularity = 10)
      super(world_size, my_color)
      @granularity = granularity
      @side_length = (@world_size / @granularity).ceil
      # @map = Array.new(@side_length ** 2, 0)
      @astar = Astar.new(@side_length, @side_length)
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
      coords = [((x - world_x_min) / @granularity).to_i, 
             ((world_y_max - y) / @granularity).to_i]
      constrain_array_coordinates(*coords)
    end
    
    def constrain_array_coordinates(*coords)
      coords.map do |v|
        if    v < 0                then 0
        elsif v > (@side_length-1) then @side_length - 1
        else                            v
        end
      end
    end
    
    def coord_to_index(x, y)
      y * @side_length + x
    end
    
    def observe_obstacles(response)
      super
      
      # Clear the A* search grid
      @astar.clear
      # "Draw" the obstacles onto the search grid
      obstacles.each do |o|
        vertices = o.coords.map{ |c| world_to_array_coordinates(c.x, c.y) }
        @astar.quad(vertices, -1.0)
      end
    end
    
    def search(start, goal)
      sx, sy = world_to_array_coordinates(start.x, start.y)
      gx, gy = world_to_array_coordinates(goal.x, goal.y)
      @astar.search(sx, sy, gx, gy).map do |x, y|
        Coord.new(*array_to_world_coordinates(x, y))
      end
    end
    
    # Find a random place on the map that isn't blocked by an obstacle
    def random_spot
      25.times do
        x = ((rand * @world_size) - (@world_size / 2)).to_i
        y = ((rand * @world_size) - (@world_size / 2)).to_i
        col, row = world_to_array_coordinates(x, y)
        if @astar[col, row] == @astar.initial_weight
          return Coord.new(x, y)
        end
      end
      return nil
    end
    
    def to_pdf(pdf = nil, options = {})
      super do |pdf|
        
        pdf.stroke_style(PDF::Writer::StrokeStyle.new(1))
        pdf.stroke_color Color::RGB::Red
        for row in 0..@side_length
          for col in 0..@side_length
            x, y = array_to_world_coordinates(col, row)
            pdf.rectangle(x, y, 1).stroke if @astar[col, row] != @astar.initial_weight
          end
        end
        
        if options[:paths]
          pdf.stroke_style(PDF::Writer::StrokeStyle.new(2))
          pdf.stroke_color Color::RGB::Red
          # p options[:paths]
          options[:paths].each do |path|
            if path and path.size > 1
              x, y = array_to_world_coordinates(path[0][0], path[0][1])
              shape = pdf.move_to(x, y)
              path[1..-1].each do |ax, ay|
                x, y = array_to_world_coordinates(ax, ay)
                shape.line_to(x, y)
              end
              shape.stroke
            end
          end
          pdf.stroke_style(PDF::Writer::StrokeStyle.new(1))
        end
      end
    end
  end

end