module BraveZealot
  
  class Coord
    attr_accessor :x, :y
    def initialize(x, y)
      @x = x.to_f
      @y = y.to_f
    end
    
    def inspect
      "(#{x}, #{y})"
    end

    #this will return the vector between this point and the point p
    def vector_to(p)
      return Vector.new(p.x - x, p.y - y, self)
    end

    # return a coord with the two elements reversed
    def reverse
      Coord.new(y,x)
    end

    #compute the dot product
    def dot(c)
      ( (c.x * x) + (cy * y) )
    end

    def normal
      Coord.new(-y,x)
    end

    def neg
      Coord.new(-x,-y)
    end

    def minus(c)
      Coord.new(x - c.x, y - c.y)
    end
  end

  #The vector class has x and y componenets like a coordinate, but they represent
  #vector components and also contain a starting point of the vector
  class Vector < Coord
    attr_accessor :start
    def initialize(x,y,start)
      @start = start
      @x = x
      @y = y
    end

    #find the cross_product of two vectors.  This is useful for checking if a point
    #is inside of an obstacle
    def cross_product(v)
      ( (x*v.y) - (y*v.x) )
    end

    def length
      if @length.nil? then
        @length = Math::sqrt( (x**2) + (y**2) )
      end
      @length
    end

    def finish
      if @finish.nil? then
        @finish = Coord.new(start.x + x, start.y + y)
      end
      @finish
    end
  end
  
end