bzrequire 'lib/obstacle.rb'
bzrequire 'lib/pf_group.rb'
bzrequire 'lib/pf.rb'
bzrequire 'lib/pf_rand.rb'
bzrequire 'lib/pf_tan.rb'
bzrequire 'lib/indent'

module BraveZealot
  class Map
    attr_accessor :size, :bases, :obstacles, :flags, :othertanks
    
    def initialize(size)
      raise ArgumentError, "World size cannot be nil or zero" if size.nil? or size == 0
      @size = size
      @bases = []
      @obstacles = []
      @flags = []
      @othertanks = []
    end
    
    def to_gnuplot(pf)
      hs = self.size / 2
      str = unindent(<<-GNUPLOT)
        # Set up our map first:
        set xrange [-#{hs}: #{hs}]
        set yrange [-#{hs}: #{hs}]
        unset key
        set size square
        
        # Draw Obstacles:
        unset arrow
      GNUPLOT
      self.obstacles.each do |o|
        str += o.to_gnuplot
      end
      
      str += "plot '-' with vectors head\n"
      41.times do |i|
        x = ( (self.size / 40)*i - hs )
        41.times do |j|
          y = ( (self.size / 40)*j - hs )
          #puts "computing dx,dy for #{x},#{y}\n"
          dx,dy = pf.suggest_delta(x,y)
          str += "#{x} #{y} #{dx} #{dy}\n"
        end
      end
      str += "e"
      str += "\n"

      str
    end
  end
end