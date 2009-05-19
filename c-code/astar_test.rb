require 'astar'
require 'test/unit'
require 'benchmark'

class AstarTest < Test::Unit::TestCase
  def setup
    @four = Astar.new([0,0,0,0], 2)
    # @large = Astar.new((0...(1000*1000)).to_a, 1000)
  end
  
  def test_search
    assert_equal [[0,0], [1,1]], @four.search(0,0,1,1)
  end
  
  def test_arg_errors
    assert_raise(ArgumentError) { Astar.new([], 2) }
    assert_raise(ArgumentError) { Astar.new([0,0,0], 2) }
    assert_nothing_raised { Astar.new([0,0,0,0], 2) }
  end
  
  def test_large
    Benchmark.bm do |x|
      x.report("init @large") { @large = Astar.new((0...(1000*1000)).to_a, 1000) }
      x.report("search") { @large.search(0,0,999,999) }
    end
  end
end
