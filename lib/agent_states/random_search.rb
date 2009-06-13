require 'rubystats/normal_distribution'

module BraveZealot
  module RandomSearchStates
    def rsr
      # rsr_stochastics
      hq.periodic_action(1.0, 1) { rsr_choose_destination }
    end
    
    def rsr_stochastics
      @hq.periodic_action(1.0) do
        # puts "vx: #{@tank.vx}, vy: #{@tank.vy}, speed: #{@tank.speed}"
        if @pause_smart_angvel
          # Get out of our random deviation
          @pause_smart_angvel = false
        elsif @tank.speed >= 18 and rand(10) > 5
          # Cause a random deviation
          @pause_smart_angvel = true
          vel = case rand(2)
          when 0 then -0.5
          when 1 then  0.5
          end
          puts "New angvel: #{vel}"
          angvel(vel)
          speed(1.0)
        end
      end
    end
    
    def rsr_deviation
      case rand(5)
      when 0 then -1
      when 4 then 1
      else 0
      end
    end
    
    def rsr_choose_destination
      @goal = hq.map.random_spot || Coord.new(0, 0)
      puts "Random destination chosen: #{@goal.x}, #{@goal.y}"
      puts "Current location: #{@tank.x}, #{@tank.y}"
      push_next_state(:smart_follow_path, :rsr_choose_destination)
      @path = hq.map.search(@tank, @goal)
      # puts "RSR Path Before: #{@path.inspect}"
      smoothen_path!(@path)
      # puts "RSR Path After: #{@path.inspect}"
      # transition(:rsr_choose_destination, :smart_follow_path)
    end
    
    protected
    
    def smoothen_path!(path, iters = 3)
      iters.times do
        path.enum_cons(3).each do |a, b, c|
          b.x = (a.x + b.x + c.x) / 3.0
          b.y = (a.y + b.y + c.y) / 3.0
        end
      end
      path
    end
    
    def randomize_path(path, wander_variance = 5, frequency = 7)
      segsize = Rubystats::NormalDistribution.new(frequency, frequency/2)
      wander  = Rubystats::NormalDistribution.new(0, wander_variance)
      
      junctions = [path[0]]
      i = 0
      begin
        skip = segsize.rng.to_i
        skip = 1 if skip < 1
        
        i += skip
        i = path.size - 1 if i >= path.size
        
        junctions << path[i]
      end while i < path.size - 1
      
      # puts "Junctions:"
      # p junctions
      
      middle = junctions[1..-2].map do |col, row|
        begin
          pos = hq.map.constrain_array_coordinates(col + wander.rng.to_i, row + wander.rng.to_i)
        end while hq.map.astar[*pos] != hq.map.astar.initial_weight
        pos
      end
      
      # puts "Middle:"
      # p middle
      # 
      newpath = []
      ([junctions[0]] + middle + [junctions[-1]]).enum_cons(2) do |head, tail|
        hcol, hrow = head
        tcol, trow = tail
        path = hq.map.astar.search(hcol, hrow, tcol, trow)
        newpath += path
      end
      
      # puts "New Path:"
      # p newpath
      
      newpath
    end
    
  end
end