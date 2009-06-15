require(File.join(File.dirname(__FILE__), "helper"))
bzrequire 'lib/astar/astar'
require 'benchmark'

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
    
    grid.clear
    grid.triangle(1,0,  3,2,  0,3,  1.0)
    assert_grid_equal(perfect, grid)
    
    grid.clear
    grid.triangle(3,0,  0,1,  2,3,  1.0)
    assert_grid_equal(perfect.transpose, grid)
    
    perfect =
      [[1, 0, 0, 0],
       [1, 1, 0, 0],
       [1, 1, 1, 0],
       [1, 1, 1, 1]]
    
    grid.clear
    grid.triangle(0,0,  3,3,  0,3,  1.0)
    assert_grid_equal(perfect, grid)
    
    grid.clear
    grid.triangle(0,0,  3,0,  3,3,  1.0)
    assert_grid_equal(perfect.transpose, grid)

    perfect =
      [[1, 1, 0, 0],
       [1, 1, 1, 1],
       [1, 1, 0, 0],
       [0, 0, 0, 0]]
    
    grid.clear
    grid.triangle(0,0,  3,1,  0,2,  1.0)
    assert_grid_equal(perfect, grid)
    
    grid.clear
    grid.triangle(0,0,  2,0,  1,3,  1.0)
    assert_grid_equal(perfect.transpose, grid)
  end
  
  def test_triangle_vertex_sort
    grid = Astar.new(4, 4)
    grid.clear
    grid.triangle(0,0,  0,3,  3,3,  1.0)
    assert_grid_equal([[1,0,0,0],[1,1,0,0],[1,1,1,0],[1,1,1,1]], grid)

    grid.clear
    grid.triangle(0,0,  3,3,  0,3,  1.0)
    assert_grid_equal([[1,0,0,0],[1,1,0,0],[1,1,1,0],[1,1,1,1]], grid)

    grid.clear
    grid.triangle(0,3,  0,0,  3,3,  1.0)
    assert_grid_equal([[1,0,0,0],[1,1,0,0],[1,1,1,0],[1,1,1,1]], grid)

    grid.clear
    grid.triangle(0,3,  3,3,  0,0,  1.0)
    assert_grid_equal([[1,0,0,0],[1,1,0,0],[1,1,1,0],[1,1,1,1]], grid)

    grid.clear
    grid.triangle(3,3,  0,0,  0,3,  1.0)
    assert_grid_equal([[1,0,0,0],[1,1,0,0],[1,1,1,0],[1,1,1,1]], grid)

    grid.clear
    grid.triangle(3,3,  0,3,  0,0,  1.0)
    assert_grid_equal([[1,0,0,0],[1,1,0,0],[1,1,1,0],[1,1,1,1]], grid)
  end
  
  def test_rectangle
    grid = Astar.new(4, 4)
    grid.rectangle(1,1,  2,2,  1.0)
    assert_grid_equal([[0,0,0,0],[0,1,1,0],[0,1,1,0],[0,0,0,0]], grid)
  end
  
  def test_quad
    grid = Astar.new(6, 6)
    grid.quad([[1, 1], [4, 2],
               [5, 5], [0, 5]], 1.0)
    assert_grid_equal([[0,0,0,0,0,0],[0,1,1,0,0,0],[0,1,1,1,1,0],
                       [0,1,1,1,1,0],[1,1,1,1,1,1],[1,1,1,1,1,1]], grid)
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
    grid = Astar.new(4, 4)
    grid.rectangle(1,1,  2,2,  2.0)
    tb = grid.search(0,1, 3,2)
    assert_equal [[0, 1], [0, 2], [1, 3], [2, 3], [3, 2]], tb
  end
  
  def test_winding_small
    arr = [
       [0,  0,  0,  0],
       [5, -1,  0,  5],
       [0,  0,  1,  4],
       [0,  2, -1,  1]
    ]
    grid = Astar.new(4, 4).from_array(arr)
    tb = grid.search(0,0, 3,3)
    assert_equal [[0,0], [1,0], [2,1], [2,2], [3,3]], tb
  end
  
  def test_indent
    arr = [
       [0, -1, -1,  0,  0],
       [0,  0, -1,  0,  0],
       [0,  0, -1,  0,  0],
       [0, -1, -1,  0,  0],
       [0,  0,  0,  0,  0]
    ]
    grid = Astar.new(5, 5).from_array(arr)
    tb = grid.search(0,0, 4,4)
    assert_equal [[0,0], [0,1], [0,2], [0,3], [1,4], [2,4], [3,4], [4,4]], tb
  end
  
  def test_no_solution
    none = Astar.new(4, 4, -1.0)
    assert_nil none.search(0,0, 3,3)
  end
  
  def test_out_of_bounds
    grid = Astar.new(4, 4)
    assert_raise(Exception) { grid.get(4, 5) }
    assert_raise(Exception) { grid.get(0, -1) }
    assert_raise(Exception) { grid.set(4, 5, -1.0) }
    assert_raise(Exception) { grid.set(-1, 5, -1.0) }
  end
  
  def test_add_grids
    grid1 = Astar.new(4, 4, 1.0)
    grid2 = Astar.new(4, 4, 0.0)
    grid2[1, 1] = -1.0
    
    assert_grid_equal [[1,1,1,1],[1,0,1,1],[1,1,1,1],[1,1,1,1]], grid1.add(grid2)
    assert_grid_uniformly_equal -1, grid2.sub(grid1)
    
    assert_raise(Exception) do
      grid3 = Astar.new(4, 5)
      grid1.add(grid3)
    end
  end
  
  def test_edges
    grid = Astar.new(7, 7)
    
    grid.edges(-1.0)
    assert_grid_uniformly_equal 0, grid
    
    grid.rectangle(2,2,  4,4,  1.0)
    assert_grid_equal [[0,0,0,0,0,0,0],
                       [0,0,0,0,0,0,0],
                       [0,0,1,1,1,0,0],
                       [0,0,1,1,1,0,0],
                       [0,0,1,1,1,0,0],
                       [0,0,0,0,0,0,0],
                       [0,0,0,0,0,0,0]], grid
    
    grid.edges(2.0)
    assert_grid_equal [[0,0,0,0,0,0,0],
                       [0,0,0,0,0,0,0],
                       [0,0,2,2,2,0,0],
                       [0,0,2,1,2,0,0],
                       [0,0,2,2,2,0,0],
                       [0,0,0,0,0,0,0],
                       [0,0,0,0,0,0,0]], grid
  end
  
  # def test_random_large
  #   @arr = []
  #   1000000.times{ @arr << (rand*1000).to_int }
  #   @random = Astar.new(@arr, 1000)
  #   # puts Benchmark.measure{ @tb = @random.search(0,0, 999,999) }
  #   # puts Benchmark.measure{ @tb = @random.search(0,0, 999,999) }
  #   # puts Benchmark.measure{ @tb = @random.search(0,0, 999,999) }
  #   @tb = @random.search(0,0, 999,999)
  #   assert @tb.size >= 1000
  #   assert @tb.size <= 2000
  #   # @arr.each_slice(100) { |slice| p slice }
  # end
  
  def test_benchmark_large
    Benchmark.bm(100) do |x|
      x.report("Initialize a 1,000,000 node graph") do
        @large = Astar.new(1000, 1000)
      end
      x.report("Search a 1,000,000 node graph") do
        @large.search(0,0,  999,999)
      end
      x.report("Draw 500 obstacles of size 500x500") do
        500.times do
          @large.triangle(0,0,  500,500,  0,500,  1.0)
        end
      end
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
