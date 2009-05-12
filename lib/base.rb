bzrequire 'lib/coord'

module BraveZealot
  class Base < Struct.new(:color, :coords)
    def center
      if @center.nil? then
        x = 0.0
        y = 0.0
        coords.each do |c|
          x += c.x
          y += c.y
        end
        x = x/coords.size
        y = y/coords.size
        @center = Coord.new(x,y)
      end
      @center
    end
  end
end
  
