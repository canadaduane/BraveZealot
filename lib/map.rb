bzrequire 'lib/obstacle.rb'
bzrequire 'lib/indent'

module BraveZealot
  class Map
    attr_accessor :world_size, :bases, :obstacles, :flags
    
    def initialize(world_size)
      raise ArgumentError, "World size cannot be nil or zero" if world_size.nil? or world_size == 0
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
      str << "plot '-' with lines\n"
      str << " 0 0 0 0\n"
      str << "e\n"
    end
  end
  
end