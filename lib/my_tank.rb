module BraveZealot
  class MyTank < Struct.new(:index, :callsign, :status,
                            :shots_available, :time_to_reload,
                            :flag, :x, :y, :angle, :vx, :vy, :angvel)

    def to_coord
      Coord.new(x,y)
    end

    def to_pdf(pdf = nil, options = {})
      return if pdf.nil?
      
      puts "Draw mytank #{x}, #{y} angle #{self.angle}"
      fill, stroke = team_colors(options[:my_color] || "none")
      
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
  