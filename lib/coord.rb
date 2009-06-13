bzrequire 'lib/kalman'

module BraveZealot
  
  module XYMethods
    # This will return the vector between this point and the point p
    def vector_to(p)
      Vector.new(p.x - self.x, p.y - self.y)
    end
    
    # return a coord with the two elements reversed
    def reverse
      Coord.new(y,x)
    end
    
    def normal
      Coord.new(-y,x)
    end
    
    def neg
      Coord.new(-x,-y)
    end
    
    def -(p)
      Coord.new(x - p.x, y - p.y)
    end
    
    def +(p)
      Coord.new(x + p.x, y + p.y)
    end
  end
  
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
    
    def initialize(x, y)
      @x = x.to_f
      @y = y.to_f
    end
    
    def inspect
      "(#{x}, #{y})"
    end
  end

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

    def length
      @length ||= Math::sqrt( (x**2) + (y**2) )
    end
  end
  
end