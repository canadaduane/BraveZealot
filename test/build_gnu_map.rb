require(File.join(File.dirname(__FILE__), "..", "bzrequire"))
bzrequire('lib/map.rb')
bzrequire('lib/obstacle.rb')

module BraveZealot
  f = Flag.new(Coord.new(100,100), 'green')
  
  c1 = Obstacle.new([Coord.new(-150,-150), Coord.new(-100,-150), Coord.new(-100,-100), Coord.new(-150,-100)])
  c2 = Obstacle.new([Coord.new(-25,0), Coord.new(0, 25), Coord.new(25,-0), Coord.new(0,-25)])
  c3 = Obstacle.new([Coord.new(-75,75), Coord.new(-50,75), Coord.new(-50,50), Coord.new(-75,50)])
  c4 = Obstacle.new([Coord.new(50,-50), Coord.new(200,-50), Coord.new(200,-200), Coord.new(50,-200)])
  m = Map.new('green', 400, [c1, c2, c3, c4], [f], [])
  
  puts m.to_gnuplot
end
