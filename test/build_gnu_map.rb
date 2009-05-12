require_relative('../lib/map.rb')
require_relative('../lib/obstacle.rb')

module BraveZealot
  f = Flag.new(Coord.new(100,100), 'green')

  m = Map.new('green',400)
  c1 = [Coord.new(-150,-150), Coord.new(-100,-150), Coord.new(-100,-100), Coord.new(-150,-100)]
  m.add_obstacle(c1)

  c2 = [Coord.new(-25,0), Coord.new(0, 25), Coord.new(25,-0), Coord.new(0,-25)]
  m.add_obstacle(c2)

  c3 = [Coord.new(-75,75), Coord.new(-50,75), Coord.new(-50,50), Coord.new(-75,50)]
  m.add_obstacle(c3)

  c4 = [Coord.new(50,-50), Coord.new(200,-50), Coord.new(200,-200), Coord.new(50,-200)]
  m.add_obstacle(c4)

  m.add_flag(f)

  

  puts m.to_gnuplot
end
