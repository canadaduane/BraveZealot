require File.join(File.dirname(__FILE__), 'ext', 'astar')

class Astar
  def inspect
    string = ""
    for y in 0...height
      for x in 0...width
        value = self[x, y]
        string << (value == initial_weight ? '-' : 'x')
      end
      string << "\n"
    end
    string
  end
  
  def quad(coords, weight)
    triangle(
      coords[0].x, coords[0].y,
      coords[1].x, coords[1].y,
      coords[2].x, coords[2].y,
      weight
    )
    triangle(
      coords[0].x, coords[0].y,
      coords[2].x, coords[2].y,
      coords[3].x, coords[3].y,
      weight
    )
  end
  
  def from_array(array)
    for y in 0...height
      for x in 0...width
        self[x, y] = array[y][x].to_f
      end
    end
    self
  end
end
