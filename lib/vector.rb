bzrequire 'lib/coord'

module BraveZealot
  class Vector < Coord
    def initialize(x, y)
      @x = x
      @y = y
    end

    # Find the cross_product of two vectors.  Useful for checking if a point
    # is inside of an obstacle.
    def cross(v)
      (v.y * x) - (v.x * y)
    end

    def dot(v)
      (v.x * x) + (v.y * y)
    end

    def unit
      @unit ||= Vector.new( x / length, y / length )
    end

    def length
      @length ||= Math::sqrt( (x**2) + (y**2) )
    end
    
    def angle
      Math.atan2(y, x)
    end
    
    def angle_diff(other)
      theta = angle
      phi = other.angle
      Math.atan2(Math.sin(theta - phi), Math.cos(theta - phi))
    end
  end
end