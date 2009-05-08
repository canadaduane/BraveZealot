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
  end
  
end