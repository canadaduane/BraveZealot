bzrequire 'lib/obstacle.rb'
bzrequire 'lib/indent'
map.to_gnuplot{ "some more gnuplot code" }
module BraveZealot
  class Map
    attr_accessor :world_size, :bases, :obstacles, :flags
    
    def initialize(world_size)
      raise ArgumentError, "World size cannot be nil or zero" if size.nil? or size == 0
      @world_size = world_size
      @bases      = []
      @obstacles  = []
      @flags      = []
    end
    
    def world_x_min
      @world_x_min ||= -@world_size / 2
    end
    
    def world_x_max
      @world_x_max ||=  @world_size / 2
    end
    
    def world_y_min
      @world_y_min ||= -@world_size / 2
    end
    
    def world_y_max
      @world_y_max ||=  @world_size / 2
    end
    
    def obstacles_plot_string
      hs = @world_size / 2
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
      str
    end
    
    def to_gnuplot
      hs = @world_size / 2
      str = obstacles_plot_string
      str << yield if block_given?
      str << "e\n"
    end
  end
  
  class MapPotentialField < Map
    def to_gnuplot
      super do
        str = "plot '-' with vectors head\n"
        41.times do |i|
          x = ( (@world_size / 40)*i - hs )
          41.times do |j|
            y = ( (@world_size / 40)*j - hs )
            #puts "computing dx,dy for #{x},#{y}\n"
            dx,dy = pf.suggest_delta(x,y)
            str += "#{x} #{y} #{dx} #{dy}\n"
          end
        end
        str
      end
    end
  end
end