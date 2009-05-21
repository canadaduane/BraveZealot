bzrequire 'lib/map'
bzrequire 'lib/astar/astar'

module BraveZealot
  class MapDiscrete < Map
    attr_reader :map
    
    def initialize(world_size, granularity = 2)
      super(world_size)
      @granularity = granularity
      @side_length = (@world_size / @granularity).ceil
      @map = Array.new(@side_length ** 2, 0)
      @astar = Astar.new(@map, @side_length)
    end
    
    # the coordinates generated from this put the item directly in the center of
    # the grid as it would translate into world coordinates
    # so grid 0,0 would translate to -390, 390 assuming each grid was 20 meters wide
    def array_to_world_coordinates(col, row)
      return (world_x_min + (@granularity / 2) + (col * @granularity)), 
             (world_y_max - (@granularity / 2) - (row * @granularity))
    end
    
    # returns column, row
    def world_to_array_coordinates(x, y)
      return ((x - world_x_min) / @granularity).to_i, 
             ((world_y_max - y) / @granularity).to_i
    end
    
    def coord_to_index(x, y)
      y * @side_length + x
    end
    
    def obstacles=(obstacles)
      @obstacles = obstacles
      # instead of asking each location if its center is in any of
      # of the obstacles, we can ask each obstacle which locations it
      # blocks
      obstacles.each do |o|
        o.locations_blocked(self).each do |c|
          @map[coord_to_index(c.x,c.y)] = -1
        end
      end
    end
    
    def search(start, goal)
      @astar.search(start.x, start.y, goal.x, goal.y)
    end
    
    def to_gnuplot
      super do
        for idx in 1..@side_length 
          str << "set arrow from " +
                "#{idx*@granularity},#{-1*@side_length*@granularity} to " +
                "#{idx*@grandularity},#{@side_length*@granularity} nohead lt 1\n"
          str << "set arrow from " +
                "#{-1*@side_length*@granularity},#{idx*@granularity} to " +
                "#{@side_length*@grandularity},#{idx*@granularity} nohead lt 1\n"
        end
        #for row in 0..@side_length
        #  for col in 0..@side_length
        #    if @map[coord_to_index(col, row)] == -1
        #      str << "set arrow from " +
        #          "#{row*@granularity - },#{} to " +
        #          "#{},#{} nohead lt 3\n" 
        #    end
        #  end
        #end
      end
    end
    
  end
  
  # class MapDiscrete < Map
  #   granularity = 20
  #   attr_accessor :hq
  #   def initialize(size, hq)
  #     @size = size.to_i
  #     @obstacles = []
  #     @flags = []
  #     @chunks = []
  #     @hq = hq
  #     @hs = @size /2
  #     
  #     @chunks_per_side = (@size / granularity).ceil
  #     (1..@chunks_per_side).each do |y|
  #       (1..@chunks_per_side).each do |x|
  #         #puts "pushing #{@chunks.size} at #{x-1},#{y-1}"
  #         @chunks.push(Chunk.new(self, x-1, y-1))
  #       end
  #     end
  #   end
  # 
  #   def to_gnuplot
  #     str = "#set up our map first\n"
  #     hs = @size/2
  #     str += "set xrange [-#{hs}: #{hs}]\n"
  #     str += "set yrange [-#{hs}: #{hs}]\n"
  #     str += "unset key\n"
  #     str += "set size square\n"
  #     str += "# Draw Obstacles:\n" 
  #     str += "unset arrow\n"
  #     @obstacles.each do |o|
  #       str += o.to_gnuplot
  #     end
  # 
  #     @chunks.each do |c|
  #       str += c.to_gnuplot
  #     end
  #     str += "plot '-' with lines\n"
  #     str += "0 0 0 0\n"
  #     str += "e\n"
  #     str
  #   end
  #   
  #   # Return the successor chunks of x, y
  #   def succ(x, y)
  #     [unblocked_chunk(x-1, y-1),
  #      unblocked_chunk(x  , y-1),
  #      unblocked_chunk(x+1, y-1),
  #      unblocked_chunk(x-1, y  ),
  #      unblocked_chunk(x  , y  ),
  #      unblocked_chunk(x+1, y  ),
  #      unblocked_chunk(x-1, y+1),
  #      unblocked_chunk(x  , y+1),
  #      unblocked_chunk(x+1, y+1)
  #     ].compact
  #   end
  #   
  #   # Return unblocked chunk at x, y or nil if it is blocked
  #   # or nil if x or y is out of range
  #   def unblocked_chunk(x, y)
  #     if x >= 0 and x < @chunks_per_side and
  #        y >= 0 and y < @chunks_per_side
  #       c = chunk(x, y)
  #       c unless c.blocked?
  #     end
  #   end
  #   
  #   # Return the chunk at x, y (measured in chunk units)
  #   def chunk(x, y)
  #     #puts "getting #{x}, #{y} at #{y*@chunks_per_side+x}"
  #     @chunks[(y*@chunks_per_side)+x]
  #   end
  #   
  #   # Return the chunk at x, y (measured in world units)
  #   def chunk_at_point(x, y)
  #     chunk(((x + @hs)  / granularity).to_i, ((y + @hs) / granularity).to_i)
  #   end
  #   
  #   def chunks_per_side
  #     @chunks_per_side
  #   end
  # 
  #   def goal
  #     if @goal.nil? then
  #       flags.each do |f|
  #         if f.color != @hq.my_color then
  #           @goal = chunk_at_point(f.x, f.y)
  #           break
  #         end
  #       end
  #       @goal = chunk_at_point(0.0, 0.0) if @goal.nil?
  #     end
  #     @goal
  #   end
  # 
  #   def goal?(n)
  #     goal.eql?(n)
  #   end
  # 
  #   #give the heuristic function of the chunk passed in (ie straight line distance to the goal node)
  #   def heuristic(c)
  #     if $options.penalty_mode then
  #       c.center.vector_to(goal.center).length * c.penalty #how awesome is that function?
  #     else 
  #       case $options.heuristic
  #       when 'arc' then c.center.vector_to(goal.center).length*Math::PI
  #       when 'poly' then ((c.center.vector_to(goal.center).length**2) + 183)
  #       else c.center.vector_to(goal.center).length
  #       end
  #     end
  #   end
  # end
  # 
  # class Chunk
  #   attr_reader :center, :corners, :map, :penalty
  #   attr_reader :x, :y
  #   
  #   def initialize(map, x_chunk, y_chunk)
  #     @map = map
  #     hs = map.size/2
  # 
  #     @x = x_chunk
  #     @y = y_chunk
  # 
  #     #first we add the four corners
  #     @corners = []
  #     @corners.push(Coord.new((x_chunk*MapDiscrete::granularity) -hs, (y_chunk*MapDiscrete::granularity) -hs)) #Lower Left
  #     @corners.push(Coord.new(((x_chunk+1)*MapDiscrete::granularity) -hs, (y_chunk*MapDiscrete::granularity) -hs)) #Lower Right
  #     @corners.push(Coord.new(((x_chunk+1)*MapDiscrete::granularity) -hs, ((y_chunk+1)*MapDiscrete::granularity) -hs)) #Upper Right
  #     @corners.push(Coord.new((x_chunk*MapDiscrete::granularity) -hs, ((y_chunk+1)*MapDiscrete::granularity) -hs)) #Upper Left
  # 
  #     #next we determine the center of the chunk
  #     @center = Coord.new((x_chunk*MapDiscrete::granularity) + (MapDiscrete::granularity/2) -hs, (y_chunk*MapDiscrete::granularity) + (MapDiscrete::granularity/2) -hs)
  #   end
  # 
  #   def blocked?
  #     if @blocked.nil? then
  #       @blocked = false
  #       @map.obstacles.each do |o|
  #         if o.contains_point(@center) then
  #           @blocked = true
  #           break
  #         end
  #       end
  #     end
  #     @blocked
  #   end
  # 
  #   def penalty
  #     if @penalty.nil? then
  #       @penalty = 1
  #       if @x == 0 or @x == ((map.chunks_per_side)-1) then
  #         @penalty = 1.5
  #       elsif @y == 0 or @y == ((map.chunks_per_side)-1) then
  #         @penalty = 1.5
  #       else
  #         if map.chunk(@x-1,@y).blocked? then
  #           @penalty = 1.5
  #         elsif map.chunk(@x+1,@y).blocked? then
  #           @penalty = 1.5
  #         elsif map.chunk(@x,@y-1).blocked? then
  #           @penalty = 1.5
  #         elsif map.chunk(@x,@y+1).blocked? then
  #           @penalty = 1.5
  #         end
  #       end
  #     end
  #     @penalty
  #   end
  # 
  #   def penalty=(p)
  #     @penalty = p
  #   end
  # 
  #   def to_gnuplot
  #     str = ""
  #     tl = @corners[3]
  #     tr = @corners[2]
  #     br = @corners[1]
  #     bl = @corners[0]
  #     #we only need to draw the top and right lines of each sqaure
  #     str += "set arrow from #{tl.x}, #{tl.y} to #{tr.x}, #{tr.y} nohead lt 7\n"
  #     str += "set arrow from #{tr.x}, #{tr.y} to #{br.x}, #{br.y} nohead lt 7\n"
  # 
  #     if $options.debug then
  #       #if blocked? then
  #       #  str += "set arrow from #{tl.x}, #{tl.y} to #{br.x}, #{br.y} nohead lt 1\n"
  #       #end
  #       if penalty > 1.6 then
  #         str += "set arrow from #{bl.x}, #{bl.y} to #{tr.x}, #{tr.y} nohead lt 8\n"
  #       end
  #     end
  #     str
  #   end
  #   
  #   # Allow Chunk objects to work nicely with Set and Hash
  #   def hash
  #     @x * @y
  #   end
  # 
  #   def succ
  #     if @succ.nil? then
  #       @succ = @map.succ(@x, @y)
  #     end
  #     @succ
  #   end
  #   
  #   def eql?(other)
  #     @x == other.x && @y == other.y
  #   end
  # 
  #   def goal?
  #     @map.goal?(self)
  #   end
  # 
  #   def to_coord
  #     Coord.new(@x, @y)
  #   end
  # 
  #   def h
  #     @h ||= @map.heuristic(self)
  #   end
  # 
  #   def g=(cost)
  #     @g = cost
  #   end
  # 
  #   def g
  #     @g ||= 0
  #   end
  # 
  #   def cost
  #     g + h
  #   end
  # 
  #   def actual_cost
  #     list = predecessors + [self]
  #     last = nil
  #     cost = 0.0
  #     list.each do |n|
  #       if last.nil? then
  #         last = n
  #       else
  #         cost += last.center.vector_to(n.center).length
  #         last = n
  #       end
  #     end
  #     cost
  #   end
  # 
  #   def predecessors=(p)
  #     @predecessors = p
  #   end
  # 
  #   def predecessors
  #     @predecessors ||= []
  #   end
  #   alias_method :priority, :cost
  # end
end