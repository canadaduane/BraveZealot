module BraveZealot
  class Shot < Struct.new(:x, :y, :vx, :vy)
    include Kalman
  end
end
  