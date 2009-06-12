require(File.join(File.dirname(__FILE__), "helper"))
bzrequire 'lib/astar/astar'
require 'benchmark'

class Astar
  def inspect
    string = ""
    for y in 0...height
      for x in 0...width
        value = self[x, y]
        string << (value == 0 ? '- ' : 'x ')
      end
      string << "\n"
    end
    string
  end
end

class AstarTest < Test::Unit::TestCase
  def test_search
    four = Astar.new(2, 2)
    assert_equal [[0,0], [1,1]], four.search(0,0,1,1)
  end
  
  def test_arg_errors
    assert_raise(ArgumentError) { Astar.new(0) }
    assert_raise(ArgumentError) { Astar.new(0, 0) }
    assert_nothing_raised { Astar.new(1, 1) }
    assert_nothing_raised { Astar.new(5, 5, 0) }
  end
  
  def test_get_set
    # Initialize a blank 2d map
    grid = Astar.new(2, 2)
    assert_grid_uniformly_equal(0.0, grid)
    
    for x in 0..1
      for y in 0..1
        grid[x, y] = 1.0
      end
    end
    assert_grid_uniformly_equal(1.0, grid)
    
    for x in 0..1
      for y in 0..1
        grid.set(x, y, 2.0)
      end
    end
    assert_grid_uniformly_equal(2.0, grid)
  end
  
  def test_clear
    # Initialize a blank 2d map
    grid = Astar.new(2, 2, 5.0)
    assert_grid_uniformly_equal(5.0, grid)
    
    # Can specify a 'clear' weight
    grid.clear(-1.0)
    assert_grid_uniformly_equal(-1.0, grid)
    
    # Should use default weight of 5.0 from initialize method
    grid.clear
    assert_grid_uniformly_equal(5.0, grid)
  end
  
  def test_pixel_perfect_triangle
    grid = Astar.new(4, 4)
    perfect =
      [[0, 1, 0, 0],
       [0, 1, 1, 0],
       [1, 1, 1, 1],
       [1, 1, 0, 0]]
    
    grid.triangle(1,0,  3,2,  0,3,  1.0)
    p grid
    # assert_grid_equal(perfect, grid)
    
    grid.clear
    grid.triangle(3,0,  0,1,  2,3,  1.0)
    p grid
    assert_grid_equal(perfect.transpose, grid)
  end
  
  def test_triangle
    grid = Astar.new(10, 10)
    # grid.triangle(0, 0, 0, 3, 3, 3, 1.0)
    # grid.triangle(0, 0, 3, 3, 0, 3, 1.0)
    # grid.triangle(0, 3, 0, 0, 3, 3, 1.0)
    # grid.triangle(0, 3, 3, 3, 0, 0, 1.0)
    # grid.triangle(3, 3, 0, 0, 0, 3, 1.0)
    # grid.triangle(3, 3, 0, 3, 0, 0, 1.0)
    grid.triangle(1, 9,  5, 1,  8, 0,  1.0)
  end
  
  def test_obstacle
    # Without an obstacle, the traceback should go straight through the middle
    nine = Astar.new(3, 3)
    assert_equal [[0, 0], [1, 1], [2, 2]], nine.search(0,0, 2,2)
    
    # With an obstacle in the center, we should have to go around
    nine[1, 1] = -1.0
    assert_equal [[0, 0], [0, 1], [1, 2], [2, 2]], nine.search(0,0, 2,2)
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
  
  def test_indent
    arr = [
       0, -1, -1,  0,  0,
       0,  0, -1,  0,  0,
       0,  0, -1,  0,  0,
       0, -1, -1,  0,  0,
       0,  0,  0,  0,  0
    ]
    map = Astar.new(arr, 5)
    tb = map.search(0,0, 4,4)
    assert_equal [[0,0], [0,1], [0,2], [0,3], [1,4], [2,4], [3,4], [4,4]], tb
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
    four = Astar.new(4, 4)
    four.add_rect(1,1,  2,1,  -1);
    assert_equal([0,0,0,0, 0,-1,-1,0, 0,0,0,0, 0,0,0,0], four.map)
  end
  
  def benchmark_large
    Benchmark.bm(10) do |x|
      x.report("init @large")   { @large = Astar.new([0] * 1_000_000, 1000) }
      x.report("search @large") { @large.search(0,0,999,999) }
    end
  end
  
  def assert_grid_uniformly_equal(value, grid)
    for x in 0..1
      for y in 0..1
        assert_equal value, grid.get(x, y)
        assert_equal value, grid[x, y]
      end
    end
  end
  
  def assert_grid_equal(array, grid)
    array.each_with_index do |rows, y|
      rows.each_with_index do |value, x|
        assert_equal value, grid[x, y], "x: #{x}, y: #{y}"
      end
    end
  end
end
