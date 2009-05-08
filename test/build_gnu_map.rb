require_relative('../lib/map.rb')
require_relative('../lib/obstacle.rb')

module BraveZealot
  f = Flag.new(Coord.new(100,100), 'green')

  m = Map.new('green',400)
  #c1 = [Coord.new(10,10), Coord.new(10,11), Coord.new(11,11), Coord.new(11,10)]
  #m.addObstacle(c1)

  c2 = [Coord.new(0,0), Coord.new(25, -25), Coord.new(0,-50), Coord.new(-25,-25)]
  m.addObstacle(c2)

  c3 = [Coord.new(-50,50), Coord.new(-40,50), Coord.new(-40,40), Coord.new(-30,40), Coord.new(-30,30), Coord.new(-50,30)]
  m.addObstacle(c3)

  m.addFlag(f)

  

  puts m.to_gnuplot
end
