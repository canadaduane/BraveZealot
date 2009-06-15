bzrequire 'lib/kalman'
bzrequire 'lib/xy_methods'

module BraveZealot

  class Coord
    attr_accessor :x, :y
    
    include Kalman
    include XYMethods
    
    alias :pre_kalman_initialize :kalman_initialize
    def kalman_initialize(mu = nil, sigma = nil, sigma_x = nil)
      sigma ||= NMatrix.float(6, 6).diagonal([400, 0.0, 0.0, 400, 0.0, 0.0])
      sigma_x ||= NMatrix.float(6, 6).diagonal([0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
      pre_kalman_initialize(mu, sigma, sigma_x)
    end

    def dot(v)
      (v.x * x) + (v.y * y)
    end
    
    def initialize(x, y)
      @x = x.to_f
      @y = y.to_f
    end
    
    def inspect
      "(#{x}, #{y})"
    end
  end

  class Vector < Coord
    def self.angle(theta)
      Vector.new(Math::cos(theta), Math::sin(theta))
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
      phi = other.respond_to?(:angle) ? other.angle : other_segment
      Math.atan2(Math.sin(theta - phi), Math.cos(theta - phi))
    end
  end

  class Segment
    attr_accessor :point, :vector
    def initialize(point, vector)
      @point = point
      @vector = vector
    end

    def intersection(other_segment)
      if parallel?(other_segment) then
        return false,Coord.new(0,0)
      end

      w = point.vector_to(other_segment.point)
      u = other_segment.vector
      v = vector
  
      t = ( u.normal.dot(w) ) / ( u.normal.dot(v) )

      return true, Coord.new( point.x + (t*vector.x) , point.y + (t*vector.y) )
    end

    def parallel?(other_segment)
      ud = vector.unit.dot(other_segment.vector.unit)
      ( ud.abs == 1.0 )
    end
  end
end