bzrequire 'lib/map'
bzrequire 'lib/astar/astar'
require 'rubystats/normal_distribution'

module BraveZealot
  class MapDiscrete < Map
    attr_reader :astar
    
    def initialize(world_size, my_color, granularity = 10)
      super(world_size, my_color)
      @granularity = granularity
      @side_length = (@world_size / @granularity).ceil
      # @map = Array.new(@side_length ** 2, 0)
      @astar = Astar.new(@side_length, @side_length, 100.0)
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
    
    # Returns true if the coordinate is in the world, and not on an obstacle
    def in_world_space?(coord)
      ax, ay = world_to_array_coordinates(coord.x, coord.y)
      in_world_range?(coord) && @astar[ax, ay] == @astar.initial_weight
    end
    
    def constrain_array_coordinates(*coords)
      coords.map do |v|
        if    v < 0                then 0
        elsif v > (@side_length-1) then @side_length - 1
        else  v
        end
      end
    end

    def update_shadows
      ws = world_size
      layers = []
      @othertanks.each do |ot|
        a = Astar.new(@side_length, @side_length, 0.0)
        @obstacles.each do |ob|
          #find which two coords make up the max/min angle with where i am 
          min = nil
          min_ang = nil
          max = nil
          max_ang = nil
          ob.coords.each do |c|
            ang = Math::atan2(c.y - ot.y, c.x - ot.x)
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
          v = ot.vector_to(min)
          projected_min = Coord.new(min.x + (ws * v.x), min.y + (ws * v.y))
          v = ot.vector_to(max)
          projected_max = Coord.new(max.x + (ws * v.x), max.y + (ws * v.y))

          #draw the shaded region onto the astar map
          a.quad([min,max,projected_min,projected_max].map{ |c| world_to_array_coordinates(c.x,c.y)}, -1.0)
        end
        #add this astar map to my list of layers
        layers.push(a)
      end
      layers.each do |l|
        @astar.add(l)
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
      @astar.edges(1000.0)
      update_shadows
    end
    
    def search(start, goal, smoothness = 2)
      sx, sy = world_to_array_coordinates(start.x, start.y)
      gx, gy = world_to_array_coordinates(goal.x, goal.y)
      if (path = @astar.search(sx, sy, gx, gy))
        path = path.map do |x, y|
          Coord.new(*array_to_world_coordinates(x, y))
        end
        smoothen_path!(path, smoothness)
      end
    end
    
    def smoothen_path!(path, iters = 3)
      iters.times do
        path.enum_cons(3).each do |a, b, c|
          b.x = (a.x + b.x + c.x) / 3.0
          b.y = (a.y + b.y + c.y) / 3.0
        end
      end
      path
    end
    
    def randomize_path!(path, wander_variance = 40, smoothness = 5)
      return if path.nil? or path.size <= 2
      wander  = Rubystats::NormalDistribution.new(0, wander_variance)
      
      path[1..-2].each do |coord|
        begin
          wx, wy = wander.rng, wander.rng
          check_coord = Coord.new(coord.x + wx, coord.y + wy)
        end while !in_world_space?(check_coord)
        
        coord.x = check_coord.x
        coord.y = check_coord.y
      end
      
      smoothen_path!(path, smoothness)
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
        for row in 0...@side_length
          for col in 0...@side_length
            x, y = array_to_world_coordinates(col, row)
            pdf.rectangle(x, y, 1).stroke if @astar[col, row] != @astar.initial_weight
          end
        end
        
        if options[:paths]
          pdf.stroke_style(PDF::Writer::StrokeStyle.new(2))
          pdf.stroke_color Color::RGB::Blue
          # p options[:paths]
          options[:paths].each do |path|
            if path and path.size > 1
              x, y = path[0].x, path[0].y
              shape = pdf.move_to(x, y)
              path[1..-1].each do |coord|
                shape.line_to(coord.x, coord.y)
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