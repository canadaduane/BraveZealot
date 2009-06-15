bzrequire 'lib/coord'
bzrequire 'lib/team_colors'
bzrequire 'lib/rect_methods'

# require 'pdf/writer'

module BraveZealot
  class Base
    attr_accessor :color, :coords
    
    include RectMethods
    
    def initialize(color, coords)
      @color, @coords = color, coords
    end
    
    def to_pdf(pdf = nil, options = {})
      return if pdf.nil?
      
      fill, stroke = team_colors(color)
      
      # Draw the base
      pdf.stroke_style(PDF::Writer::StrokeStyle.new(1))
      pdf.stroke_color stroke
      pdf.fill_color   fill
      
      shape = pdf.move_to(coords[-1].x, coords[-1].y)
      coords.each { |c| shape.line_to(c.x, c.y) }
      shape.fill_stroke
      
      pdf.stroke_style(PDF::Writer::StrokeStyle.new(1))
    end
    
  end
end
  
