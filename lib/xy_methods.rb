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
end