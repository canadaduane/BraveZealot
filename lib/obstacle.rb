module BraveZealot
  class Obstacle
    attr_accessor :coordinates
    def initialize(coords)
      @coordinates = coords
    end

    def to_gnuplot
      str = ""
      first = nil
      last = nil
      @coordinates.each do |c|
        if ( first.nil? ) then
          first = c
        else
          str += "set arrow from #{last.x}, #{last.y} to #{c.x}, #{c.y} nohead lt 3\n"
        end
        last = c
      end
      str += "set arrow from #{last.x}, #{last.y} to #{first.x}, #{first.y} nohead lt 3\n"
      str
    end

    def center
      if @center.nil? then
        x = 0.0
        y = 0.0
        @coordinates.each do |c|
          x += c.x
          y += c.y
        end
        x = x/@coordinates.size
        y = y/@coordinates.size
        @center = Coord.new(x,y)
      end
      @center
    end
  end
end
