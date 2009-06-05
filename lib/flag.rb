bzrequire 'lib/team_colors'

module BraveZealot
  class Flag < Struct.new(:color, :possession, :x, :y)
    include Kalman
    def to_pdf(pdf = nil, options = {})
      return if pdf.nil?
      
      fill, stroke = team_colors(self.color)
      
      # Draw the flag pole
      pdf.stroke_style(PDF::Writer::StrokeStyle.new(3))
      pdf.stroke_color Color::RGB::Gray
      pdf.move_to(x, y).line_to(x, y + 20).stroke
      
      # Draw the flag
      pdf.stroke_style(PDF::Writer::StrokeStyle.new(1))
      pdf.stroke_color stroke
      pdf.fill_color   fill
      
      pdf.move_to(x, y + 20).
          curve_to(x + 5, y + 25, x + 10, y + 15, x + 15, y + 20).
          curve_to(x + 15, y + 15, x + 10, y + 10, x + 5, y + 15).
          line_to(x, y + 10).
          close_fill_stroke
    end
  end
end