module BraveZealot
  module RectMethods
    # Check if a point existst inside an obstacle
    def contains_point?(p)
      if rect? then
        # Get xmax and xmin
        xs = coords.map{ |c| c.x }
        ys = coords.map{ |c| c.y }
        
        p.x.between?(xs.min, xs.max) and
        p.y.between?(ys.min, ys.max)
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
    
    def center
      @center ||= begin
        x = 0.0
        y = 0.0
        @coords.each do |c|
          x += c.x
          y += c.y
        end
        Coord.new(x / @coords.size, y / @coords.size)
      end
    end

    def side_length
      @side_length ||= sides.map{ |s| s.length }.max
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
    
    def rect?
      if @rect.nil? then
        @rect = !sides.any? { |s| s.x.nonzero? && s.y.nonzero? }
      end
      @rect
    end
  end
end