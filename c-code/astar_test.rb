require 'astar'
require 'test/unit'
require 'benchmark'

class AstarTest < Test::Unit::TestCase
  def setup
  end
  
  # def test_search
  #   four = Astar.new([0,0,0,0], 2)
  #   assert_equal [[0,0], [1,1]], four.search(0,0,1,1)
  # end
  # 
  # def test_arg_errors
  #   assert_raise(ArgumentError) { Astar.new([], 2) }
  #   assert_raise(ArgumentError) { Astar.new([0,0,0], 2) }
  #   assert_nothing_raised { Astar.new([0,0,0,0], 2) }
  # end
  # 
  # def test_obstacle
  #   # Without an obstacle, the traceback should go straight through the middle
  #   nine = Astar.new([0,0,0, 0,0,0, 0,0,0], 3)
  #   assert_equal [[0, 0], [1, 1], [2, 2]], nine.search(0,0, 2,2)
  #   
  #   # With an obstacle in the center, we should have to go around
  #   nine_obs = Astar.new([0,0,0, 0,-1,0, 0,0,0], 3)
  #   assert_equal [[0, 0], [0, 1], [1, 2], [2, 2]], nine_obs.search(0,0, 2,2)
  # end
  #
  # def test_random_large
  #   Benchmark.bm(10) do |x|
  #     x.report("init random") do
  #       @arr = []
  #       1_000_000.times{ @arr << (rand*1000).to_int }
  #       @random = Astar.new(@arr, 1000)
  #     end
  #     x.report("search random") do
  #       @tb = @random.search(0,0, 999,999)
  #     end
  #   end
  #   p @arr
  #   p @tb
  # end
  
  def test_random_small
    arr = [
       0,  0,  0,  0,
       5, -1,  0,  5,
       0,  0,  1,  4,
       0,  2, -1,  1
    ]
    @random = Astar.new(arr, 4)
    @tb = @random.search(0,0, 3,3)
    assert_equal [[0,0], [1,0], [2,1], [2,2], [3,3]], @tb
    p @tb
  end
  
  def benchmark_large
    Benchmark.bm(10) do |x|
      x.report("init @large")   { @large = Astar.new([0] * 1_000_000, 1000) }
      x.report("search @large") { @large.search(0,0,999,999) }
    end
  end
end
