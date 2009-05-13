bzrequire 'lib/map'
module BraveZealot
  class MapDiscrete < Map
    CHUNK_SIZE = 20
    def initialize(team, size)
      @team = team
      @size = size.to_i
      @obstacles = []
      @flags = []
      @chunks = []
      
      @chunks_per_side = (@size / CHUNK_SIZE).ceil
      (1..@chunks_per_side).each do |y|
        (1..@chunks_per_side).each do |x|
          @chunks.push(Chunk.new(self, x-1, y-1))
        end
      end
    end

    def to_gnuplot
      str = "#set up our map first\n"
      hs = @size/2
      str += "set xrange [-#{hs}: #{hs}]\n"
      str += "set yrange [-#{hs}: #{hs}]\n"
      str += "unset key\n"
      str += "set size square\n"
      str += "# Draw Obstacles:\n" 
      str += "unset arrow\n"
      @obstacles.each do |o|
        str += o.to_gnuplot
      end

      @chunks.each do |c|
        str += c.to_gnuplot
      end
      str += "plot '-' with lines\n"
      str += "0 0 0 0\n"
      str += "e\n"
      str
    end
  end

  class Chunk
    attr_reader :center, :corners, :blocked, :penalty, :map
    def initialize(map, x_chunk, y_chunk)
      @map = map
      hs = map.size/2

      #first we add the four corners
      @corners = []
      @corners.push(Coord.new((x_chunk*MapDiscrete::CHUNK_SIZE) -hs, (y_chunk*MapDiscrete::CHUNK_SIZE) -hs)) #Lower Left
      @corners.push(Coord.new(((x_chunk+1)*MapDiscrete::CHUNK_SIZE) -hs, (y_chunk*MapDiscrete::CHUNK_SIZE) -hs)) #Lower Right
      @corners.push(Coord.new(((x_chunk+1)*MapDiscrete::CHUNK_SIZE) -hs, ((y_chunk+1)*MapDiscrete::CHUNK_SIZE) -hs)) #Upper Right
      @corners.push(Coord.new((x_chunk*MapDiscrete::CHUNK_SIZE) -hs, ((y_chunk+1)*MapDiscrete::CHUNK_SIZE) -hs)) #Upper Left

      #next we determine the center of the chunk
      @center = Coord.new((x_chunk*MapDiscrete::CHUNK_SIZE) + (MapDiscrete::CHUNK_SIZE/2) -hs, (y_chunk*MapDiscrete::CHUNK_SIZE) + (MapDiscrete::CHUNK_SIZE/2) -hs)

      #finally we determine if this chunk is blocked and/or has a penalty assigned to it
      @blocked = false
      @penalty = 1 #1 means no penalty
    end

     def to_gnuplot
      str = ""
      tl = @corners[3]
      tr = @corners[2]
      br = @corners[1]
      #we only need to draw the top and right lines of each sqaure
      str += "set arrow from #{tl.x}, #{tl.y} to #{tr.x}, #{tr.y} nohead lt 7\n"
      str += "set arrow from #{tr.x}, #{tr.y} to #{br.x}, #{br.y} nohead lt 7\n"
    end
  end
end