bzrequire 'lib/coord'

module BraveZealot
  class Obstacle
    attr_accessor :coords
    def initialize(coords)
      @coords = coords
    end
    
    def to_pdf(pdf = nil, options = {})
      return if pdf.nil?
      
      pdf.stroke_color Color::RGB::Red
      pdf.fill_color   Color::RGB::Pink
      
      shape = pdf.move_to(coords[-1].x, coords[-1].y)
      coords.each do |c|
        shape.line_to(c.x, c.y)
      end
      shape.fill_stroke
    end
    
    # def to_gnuplot
    #   str = ""
    #   sides.each do |s|
    #     str +=  "set arrow from " +
    #             "#{s.start.x},#{s.start.y} to " +
    #             "#{s.finish.x},#{s.finish.y} nohead lt 3\n"
    #   end
    #   #if rect? then
    #   #  str += "set arrow from " +
    #   #          "#{@coords[0].x}, #{@coords[0].y} to " +
    #   #          "#{@coords[2].x}, #{@coords[2].y} nohead lt 5\n"
    #   #end
    #   str
    # end

    def center
      if @center.nil? then
        x = 0.0
        y = 0.0
        @coords.each do |c|
          x += c.x
          y += c.y
        end
        x = x/@coords.size
        y = y/@coords.size
        @center = Coord.new(x,y)
      end
      @center
    end

    def side_length
      if ( @side_length.nil? )
        @side_length = sides.map{ |s| s.length }.max
      end
      @side_length
    end

    #get a list of the sides of this obstacle represented by vectors
    def sides
      if @sides.nil? then
        @sides = []
        @coords.each_with_index do |c,i|
          if @coords[i+1].nil? then
            @sides[i] = c.vector_to(@coords.first)
          else
            @sides[i] = c.vector_to(@coords[i+1])
          end
        end
      end
      @sides
    end

    #check if a point existst inside an obstacle
    def contains_point(p)
      if rect? then
        #get xmax and xmin
        xs = coords.map{ |c| c.x }
        xmax = xs.max
        xmin = xs.min
        if !p.x.between?(xmin,xmax) then
          return false
        end

        ys = coords.map{ |c| c.y }
        ymax = ys.max
        ymin = ys.min
        if !p.y.between?(ymin, ymax) then
          return false
        end
        true
      else
        #Cross product Check
        which_side = nil
        sides.each do |s|
          if which_side.nil? then
            #puts "finding which side of the first line we are on..."
            which_side = s.cross_product(s.start.vector_to(p))
            #puts "we are on the #{which_side} side of the line..."
            which_side = if which_side.zero? then nil else which_side end
          else 
            tmp = s.cross_product(s.start.vector_to(p))
            #puts "we are the #{tmp} side of this line..."
            if ( (tmp < 0) != (which_side < 0) ) then
              return false
            end
          end
        end
        true
      end
    end

    def rect?
      if @rect.nil? then
        @rect = !sides.any? { |s| s.x.nonzero? && s.y.nonzero? }
      end
      @rect
    end

    def locations_blocked(map)
      arr = []
      indices = @coords.map do |c| 
        x,y = map.world_to_array_coordinates(c.x, c.y) 
        Coord.new(x,y)
      end
      min_x = indices.map{|c| c.x}.min.to_i
      min_y = indices.map{|c| c.y}.min.to_i
      max_x = indices.map{|c| c.x}.max.to_i
      max_y = indices.map{|c| c.y}.max.to_i
      for col in min_x.to_i..max_x
        for row in min_y..max_y
          if rect? then
            arr.push(Coord.new(col,row))
          else 
            x,y = map.array_to_world_coordinates(col,row)
            if  contains_point(Coord.new(x,y)) then
              arr.push(Coord.new(col,row))
            end
          end
        end
      end
      arr
    end
  end
end
