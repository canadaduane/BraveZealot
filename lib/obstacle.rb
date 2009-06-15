bzrequire 'lib/coord'
bzrequire 'lib/rect_methods'

module BraveZealot
  class Obstacle
    attr_accessor :coords
    include RectMethods
    
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
  end
end
