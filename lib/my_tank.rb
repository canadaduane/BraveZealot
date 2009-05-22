module BraveZealot
  class MyTank < Struct.new(:index, :callsign, :status,
                            :shots_available, :time_to_reload,
                            :flag, :x, :y, :angle, :vx, :vy, :angvel)

    def to_coord
      Coord.new(x,y)
    end

    def to_pdf(pdf = nil, options = {})
      return if pdf.nil?
      
      puts "Draw mytank #{x}, #{y}"
      fill, stroke = team_colors(options[:my_color] || "none")
      
      # Draw the tank
      pdf.stroke_style(PDF::Writer::StrokeStyle.new(1))
      pdf.stroke_color stroke
      pdf.fill_color   fill
      
      c = Math.cos(angle / 3.14159 * 180)
      s = Math.sin(angle / 3.14159 * 180)
      pdf.move_to(x, y).
          line_to(x + s, y + c).
          line_to(x + c*2, y + s*2).
          line_to(x - s, y - s).
          fill_stroke
      
    end
  end
end
  