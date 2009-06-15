require(File.join(File.dirname(__FILE__), "helper"))
bzrequire 'lib/coord'

module BraveZealot
  class TestVector < Test::Unit::TestCase

    def test_angle_diff
      tank = Coord.new(0, 0)
      
      tvec = tank.vector_to(Coord.new(0, 10))
      
      enemy = Coord.new(-3, 20)
      assert(tvec.angle_diff(tank.vector_to(enemy)).abs < Math::PI/4)
      
      enemy = Coord.new(3, 20)
      assert(tvec.angle_diff(tank.vector_to(enemy)).abs < Math::PI/4)
      
      enemy = Coord.new(9, 10)
      assert(tvec.angle_diff(tank.vector_to(enemy)).abs < Math::PI/4)
      
      enemy = Coord.new(-9, 10)
      assert(tvec.angle_diff(tank.vector_to(enemy)).abs < Math::PI/4)
      
      enemy = Coord.new(11, 10)
      assert(tvec.angle_diff(tank.vector_to(enemy)).abs > Math::PI/4)
      
      enemy = Coord.new(-11, 10)
      assert(tvec.angle_diff(tank.vector_to(enemy)).abs > Math::PI/4)
    end
    
    def test_vector_from_angle
      a = Vector.angle(Math::PI/2)
      b = Vector.angle(Math::PI/4)
      assert(a.cross(b) < 0)
      assert(b.cross(a) > 0)
    end
    
  end
end