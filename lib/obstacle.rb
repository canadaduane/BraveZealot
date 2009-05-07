module BraveZealot
  class Obstacle
    def initialize(str)
      obs = str.scan(/-?\d+\.\d+/)
      coords = []
      obs.each(){ |c| coords.push(c.to_f) }
      
      
    end
  end
end
