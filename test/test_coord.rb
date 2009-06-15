require(File.join(File.dirname(__FILE__), "helper"))
bzrequire 'lib/coord'

module BraveZealot
  class TestSegment < Test::Unit::TestCase
    context "segment intersection test" do
      setup do
        @horiz = Segment.new(Coord.new(-1,0), Vector.new(2,0))
        @vert = Segment.new(Coord.new(0,-1), Vector.new(0,2))

        @horiz2 = Segment.new(Coord.new(2,2), Vector.new(2,0))

        @vert2 = Segment.new(Coord.new(10,-10), Vector.new(0,100))
        @diag = Segment.new(Coord.new(5,50), Vector.new(10,-20))
      end
      
      should "intersect @ (0,0)" do
        int, point = @horiz.intersection(@vert)
        assert_equal true, int
        assert_equal 0.0, point.x
        assert_equal 0.0, point.y

        int, point = @vert.intersection(@horiz)
        assert_equal true,int
        assert_equal 0.0, point.x
        assert_equal 0.0, point.y
      end

      should "not intersect" do
        int, point = @horiz.intersection(@horiz2)
        assert_equal false, int

        int, point = @horiz2.intersection(@horiz)
        assert_equal false, int
      end

      should "intersect @ (10,40) " do
        int, point = @vert2.intersection(@diag)
        
        assert_equal true, int
        assert_equal 10.0, point.x
        assert_equal 40.0, point.y
      end
    end
  end
end