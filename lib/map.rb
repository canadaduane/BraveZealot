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
  end
end
