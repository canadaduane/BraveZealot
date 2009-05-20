module BraveZealot
  class MyTank < Struct.new(:index, :callsign, :status,
                            :shots_available, :time_to_reload,
                            :flag, :x, :y, :angle, :vx, :vy, :angvel)

    def to_coord
      Coord.new(x,y)
    end
  end
end
  