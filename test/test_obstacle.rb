require(File.join(File.dirname(__FILE__), "helper"))
bzrequire 'lib/obstacle'

module BraveZealot
  class TestObstacle < Test::Unit::TestCase
    context "small centered target" do
      should "be centered at 0,0" do
        coords = [[-10, -10], [10, -10], [10, 10], [-10, 10]].map{ |x, y| Coord.new(x, y) }
        o = Obstacle.new(coords)
        assert_equal(0.0, o.center.x)
        assert_equal(0.0, o.center.y)
      end
    end
    context "small off-center target" do
      should "be centered at 10,0" do
        
      end
    end
  end
end
