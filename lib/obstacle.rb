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
  end
end
