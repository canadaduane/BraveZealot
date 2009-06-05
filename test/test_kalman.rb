require(File.join(File.dirname(__FILE__), "helper"))
bzrequire 'lib/kalman'


module BraveZealot
  class KalmanFilter
    attr_accessor :x, :y
    include Kalman
    
    def initialize(x, y)
      @x, @y = x, y
    end
  end

  class TestKalman < Test::Unit::TestCase
    context "small centered target" do
      setup do
        @x, @y = 40, 20
        @kf = KalmanFilter.new(@x, @y)
      end
      
      should "Initialize sigma, mu to nil" do
        assert_nil @kf.kalman_mu
        assert_nil @kf.kalman_sigma
        assert_raise(NoMethodError) do
          @kf.x
          @kf.y
        end
      end
      
      should "Alias observed_x to x, observed_y to y" do
        assert_equal @x, @kf.observed_x
        assert_equal @y, @kf.observed_y
      end
      
      should "Keep define unaliased methods as nil" do
        assert_nil @kf.observed_vx
        assert_nil @kf.observed_vy
        assert_nil @kf.observed_ax
        assert_nil @kf.observed_ay
      end
      
      should "Match the x and y methods to their @kalman_mu entires" do
        @kf.kalman_next
        assert_equal 32, @kf.x.to_int
        assert_equal 16, @kf.y.to_int
        @kf.kalman_next
        assert_equal 37, @kf.x.to_int
        assert_equal 18, @kf.y.to_int
      end
    end
  end
end
