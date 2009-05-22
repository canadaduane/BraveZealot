bzrequire 'lib/coord'
bzrequire 'lib/team_colors'

require 'pdf/writer'

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
  
