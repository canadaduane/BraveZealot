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
    
    def rect?
      if @rect.nil? then
        @rect = !sides.any? { |s| s.x.nonzero? && s.y.nonzero? }
      end
      @rect
    end
    
  end
end
