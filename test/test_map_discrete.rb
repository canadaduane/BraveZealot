require(File.join(File.dirname(__FILE__), "helper"))
bzrequire 'lib/map_discrete'

module BraveZealot
  class TestMapDiscrete < Test::Unit::TestCase
    def test_map
      map = MapDiscrete.new(10)
    end
  
    def test_search
      map = MapDiscrete.new(10)
      coords = [[2,2], [2,-2], [-2,-2], [-2,2]].map{ |x,y| Coord.new(x, y) }
      map.obstacles = [Obstacle.new(coords)]
      # map.map.each_slice(5){ |s| p s }
      start = Coord.new(0, 0)
      goal = Coord.new(4, 4)
      p map.search(start, goal)
    end
  end
end