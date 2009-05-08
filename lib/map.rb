bzrequire 'lib/obstacle.rb'
bzrequire 'lib/pf_group.rb'
bzrequire 'lib/pf.rb'
bzrequire 'lib/pf_rand.rb'
bzrequire 'lib/pf_tan.rb'

module BraveZealot
  class Map
    attr_accessor :size, :obstacles, :flags, :tanks, :team
    def initialize(team, size)
      @team = team
      @size = size.to_i
      @obstacles = []
      @flags = []
    end

    def addObstacle(coordinates)
      @obstacles.push(Obstacle.new(coordinates))
    end
    def addFlag(f)
      @flags << f
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
      
      pf_group = PfGroup.new()
      pf_group.addMapFields(self)

      str += "plot '-' with vectors head\n"
      41.times do |i|
        x = ( (@size/40)*i - hs )
        41.times do |j|
          y = ( (@size/40)*j - hs )
          #puts "computing dx,dy for #{x},#{y}\n"
          dx,dy = pf_group.suggestDelta(x,y)
          str += "#{x} #{y} #{dx} #{dy}\n"
        end
      end
      str += "e"
      str += "\n"

      str
    end
  end
end
