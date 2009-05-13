bzrequire 'lib/coord'

module BraveZealot
  class Obstacle
    attr_accessor :coords
    def initialize(coords)
      @coords = coords
    end

    def to_gnuplot
      str = ""
      first = nil
      last = nil
      @coords.each do |c|
        if ( first.nil? ) then
          first = c
        else
          str += "set arrow from " +
                 "#{last.x}, #{last.y} to " +
                 "#{c.x}, #{c.y} nohead lt 3\n"
        end
        last = c
      end
      str += "set arrow from " +
             "#{last.x}, #{last.y} to " +
             "#{first.x}, #{first.y} nohead lt 3\n"
      str
    end

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
        @side_length = @coords.zip(@coords[1..-1] + [@coords[0]]).
          map{ |c1,c2| Math.sqrt((c2.y-c1.y)**2 + (c2.x-c1.x)**2) }.max
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
end
