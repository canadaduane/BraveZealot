require_relative 'map.rb'
module BraveZealot
  class Map
    attr_accessor :size, :obstacles, :flags, :tanks, :team
    def initialize(team, size)
      @team = team
      @size = size
      @obstacles = []
    end

    def addObstacle(coordinates)
      @obstacles.push(Obstacle.new(coordinates))
    end

    def to_gnuplot
      str = "#set up our map first\n"
      hs = @size/2
      str += "set xrange [-#{hs}: #{hs}]\n"
      str += "set yrange [-#{hs}: #{hs}]\n"
      str += "unset key\n"
      str += "set size square\n"
      str += "# Draw Obstacles:\n" 
      str += "unset arrow\n"
      @obstacles.each do |o|
        str += o.to_gnuplot
      end
      str
    end
  end
end
