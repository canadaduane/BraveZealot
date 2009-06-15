bzrequire 'lib/kalman'
bzrequire 'lib/coord'
bzrequire 'lib/shadow_methods'

module BraveZealot
  class OtherTank < Struct.new(:callsign, :color, :status, :flag, :x, :y, :angle)
    include Kalman
    include XYMethods
    include ShadowMethods
    
    def to_coord
      Coord.new(x,y)
    end
    
    def alive?
      status == 'normal'
    end

    def to_pdf(pdf = nil, options = {})
      return if pdf.nil?
      
      # puts "Draw mytank #{x}, #{y}"
      fill, stroke = team_colors(self.color)
      
      if alive?
        # Draw the tank
        pdf.stroke_style(PDF::Writer::StrokeStyle.new(1))
        pdf.stroke_color stroke
        pdf.fill_color   fill
      
        pdf.circle_at(x, y, 10).fill_stroke
        c = Math.cos(angle)
        s = Math.sin(angle)
      
        pdf.line(x, y, x+c*10, y+s*10).stroke
      end
      
    end

  end
end

  
