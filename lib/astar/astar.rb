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
      coords[0][0], coords[0][1],
      coords[1][0], coords[1][1],
      coords[2][0], coords[2][1],
      weight
    )
    triangle(
      coords[0][0], coords[0][1],
      coords[2][0], coords[2][1],
      coords[3][0], coords[3][1],
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
