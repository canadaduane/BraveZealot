module BraveZealot
  class MyTank < Struct.new(:index, :callsign, :status,
                            :shots_available, :time_to_reload,
                            :flag, :x, :y, :angle, :vx, :vy, :angvel)
  end
end
  