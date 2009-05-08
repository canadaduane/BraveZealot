require_relative 'map.rb'
module BraveZealot
  class Map
    attr_accessor :size, :obstacles, :flags, :tanks, :team
    def initialize(team, size)
      @team = team
      @size = size
    end

    def addObstacles(str)
      
    end

    def to_gnuplot
      
    end
  end
  class Coordinate
    attr_accessor :x, :y
    def initialize(x,y)
      @x = x
      @y = y
    end
  end
end
