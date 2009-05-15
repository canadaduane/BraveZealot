module BraveZealot
  class OtherTank < Struct.new(:callsign, :color, :status, :flag, :x, :y, :angle)
    def to_coord
      Coord.new(x,y)
    end
  end
end

  