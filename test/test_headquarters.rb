require(File.join(File.dirname(__FILE__), "helper"))
bzrequire 'lib/headquarters'

module BraveZealot
  class TestHeadquarters < Test::Unit::TestCase
    
    def setup
      @hq = Headquarters.new("1234")
      def @hq.tanks_on_team(color)
        case color
        when "red" then
          [OtherTank.new("t1", "red", "normal", "-", 0, 5, 0),
           OtherTank.new("t2", "red", "normal", "-", 4, 5, 0),
           OtherTank.new("t3", "red", "normal", "-", 6, 5, 0)]
        when "green" then
          [MyTank.new(0, "m1", "normal", 0, 0, "-", 0, 0, Math::PI/2, 0, 0, 0)]
        end
      end
    end
    
    def test_tanks_ahead
      enemies = @hq.tanks_ahead(Coord.new(0, 0), Math::PI/2, "red")
      assert_equal ["t1", "t2"], enemies.map{ |e| e.callsign }
      
      enemies = @hq.tanks_ahead(Coord.new(1, 5), 0, "red")
      assert_equal ["t2", "t3"], enemies.map{ |e| e.callsign }
      
      enemies = @hq.tanks_ahead(Coord.new(-1, 5), Math::PI, "red")
      assert_equal [], enemies.map{ |e| e.callsign }
      
      enemies = @hq.tanks_ahead(Coord.new(1, 5), Math::PI, "red")
      assert_equal ["t1"], enemies.map{ |e| e.callsign }
    end
    
  end
end