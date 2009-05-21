require 'astar'
require 'test/unit'
require 'benchmark'

class AstarTest < Test::Unit::TestCase
  def test_search
    four = Astar.new([0,0,0,0], 2)
    assert_equal [[0,0], [1,1]], four.search(0,0,1,1)
  end
  
  def test_arg_errors
    assert_raise(ArgumentError) { Astar.new([], 2) }
    assert_raise(ArgumentError) { Astar.new([0,0,0], 2) }
    assert_nothing_raised { Astar.new([0,0,0,0], 2) }
  end
  
  def test_obstacle
    # Without an obstacle, the traceback should go straight through the middle
    nine = Astar.new([0,0,0, 0,0,0, 0,0,0], 3)
    assert_equal [[0, 0], [1, 1], [2, 2]], nine.search(0,0, 2,2)
    
    # With an obstacle in the center, we should have to go around
    nine_obs = Astar.new([0,0,0, 0,-1,0, 0,0,0], 3)
    assert_equal [[0, 0], [0, 1], [1, 2], [2, 2]], nine_obs.search(0,0, 2,2)
  end
  
  def test_subtle_obstacle
    arr = [
       0,   0,   0,  0,
       0, 200, 200,  0,
       0, 200, 200,  0,
       0,   0,   0,  0
    ]
    subtle = Astar.new(arr, 4)
    tb = subtle.search(0,1, 3,2)
    assert_equal [[0, 1], [0, 2], [1, 3], [2, 3], [3, 2]], tb
  end
  
  def test_winding_small
    arr = [
       0,  0,  0,  0,
       5, -1,  0,  5,
       0,  0,  1,  4,
       0,  2, -1,  1
    ]
    winding = Astar.new(arr, 4)
    tb = winding.search(0,0, 3,3)
    assert_equal [[0,0], [1,0], [2,1], [2,2], [3,3]], tb
  end
  
  def test_no_solution
    none = Astar.new([-1] * 16, 4)
    assert_nil none.search(0,0, 3,3)
  end
  
  def test_random_large
    @arr = []
    1000000.times{ @arr << (rand*1000).to_int }
    @random = Astar.new(@arr, 1000)
    # puts Benchmark.measure{ @tb = @random.search(0,0, 999,999) }
    # puts Benchmark.measure{ @tb = @random.search(0,0, 999,999) }
    # puts Benchmark.measure{ @tb = @random.search(0,0, 999,999) }
    @tb = @random.search(0,0, 999,999)
    assert @tb.size >= 1000
    assert @tb.size <= 2000
    # @arr.each_slice(100) { |slice| p slice }
  end
  
  def test_add_rect
    four = Astar.new([0] * 16, 4)
    four.add_rect(1,1,  2,1,  -1);
    assert_equal([0,0,0,0, 0,-1,-1,0, 0,0,0,0, 0,0,0,0], four.map)
  end
  
  def benchmark_large
    Benchmark.bm(10) do |x|
      x.report("init @large")   { @large = Astar.new([0] * 1_000_000, 1000) }
      x.report("search @large") { @large.search(0,0,999,999) }
    end
  end
end
