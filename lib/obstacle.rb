require_relative 'map.rb'
module BraveZealot
  class Obstacle
    attr_accessor :coordinates
    def initialize(str)
      obs = str.scan(/-?\d+\.\d+/)
      coords = []
      last = nil
      obs.each_index do |i|
        c = obs[i]
        if ( last.nil? == false ) then
          if ( i % 2 == 1 ) then
            coords.push(Coordinate.new(last,c.to_f))
          end
        end
        last = c.to_f
      end
      @coordinates = coords
    end

    def to_gnuplot
      
    end

    def center
      if @center.nil? then
        x = 0.0
        y = 0.0
        @coordinates.each do |c|
          x += c.x
          y += c.y
        end
        x = x/@coordinates.size
        y = y/@coordinates.size
        @center = Coordinate.new(x,y)
      end
      @center
    end
  end
end
