bzrequire 'lib/pf.rb'
bzrequire 'lib/pf_rand.rb'
bzrequire 'lib/pf_tan.rb'
bzrequire 'lib/pf_rep.rb'

module BraveZealot

  # An Aggregate Goal is made up of sub goals which are averaged together to
  # make decisions about suggested actions
  class PfGroup

    attr_accessor :fields

    def initialize(random_background = true)
      @fields = []
      add_rand(0.15) if random_background
    end

    def add_field(f)
      @fields << f
    end
    def add_rand(factor)
        add_field(PfRand.new(factor))
    end

    def add_goal(x, y, size)
      add_field(Pf.new(x, y, size, 0, 0.2))
    end
    
    def add_obstacles(obstacles)
      obstacles.each do |o|
        add_field(PfTan.new(o.center.x, o.center.y,
          o.side_length/2, o.side_length/2, 0.5))
        add_field(PfRep.new(o.center.x, o.center.y, o.side_length, 0, 1))
      end
    end
    
    # suggest a distance and angle
    def suggest_delta(current_x, current_y)
      dx = 0.0
      dy = 0.0
      @fields.each do |f|
        fdx, fdy = f.suggest_delta(current_x, current_y)
        dx += fdx
        dy += fdy
      end
       if dx > Pf::MAX then
        dx = Pf::MAX
      elsif dx < -Pf::MAX then
        dx = -Pf::MAX
      end
      if dy > Pf::MAX then
        dy = Pf::MAX
      elsif dy < -Pf::MAX
        dy = -Pf::MAX
      end
      
      return dx, dy
    end

    # suggest a move
    def suggest_move(current_x, current_y, current_angle)
      dx,dy = suggest_delta(current_x,current_y)
      #print "current angle is #{current_angle}\n"
      #print "the goal angle is #{ang_g}\n";
      ang_g = Math.atan2(dy,dx)
      distance = Math.sqrt(dx**2 + dy**2)

      #print "dx=#{dx}, dy=#{dy}, goal_angle=#{ang_g}\n"

      a = ang_g-current_angle
      #print "we need to move through #{a} radians\n"
      if ( a.abs() > Math::PI ) then
        if ( a < 0 ) then
          a += 2*Math::PI
        else
          a -= 2*Math::PI
        end
        #print "how about we go the other way through #{a} radians?\n"
      end

      # We assume we will be updating every .1 seconds, so lets set speed and
      # angvel to reach the desired destination in .5 seconds
      speed = distance/(5 * $options.refresh * 25)
      angvel = a/(5 * $options.refresh)
      m = Move.new(speed, angvel)

      #if we don't need to move, then lets not spin
      if ( speed < 0.01 ) then
        angvel = 0
      end

      # And the final factor in our speed is based on how far off our desired
      # angle we are (Note: we should never be turning more than pi)
      speed = m.speed()*((2*((((Math::PI - a.abs()).abs())) / Math::PI ))-1)
      #speed = m.speed()*((((((Math::PI - a.abs()).abs())) / Math::PI )))
      
      m = Move.new(speed, angvel)
      return m
    end
    
    def to_gnuplot_part(world_size, detail = 40)
      hs = world_size / 2
      str = "plot '-' with vectors head\n"
      (detail + 1).times do |i|
        x = ( (world_size / detail)*i - hs )
        (detail + 1).times do |j|
          y = ( (world_size / detail)*j - hs )
          dx,dy = suggest_delta(x,y)
          str += "#{x} #{y} #{dx} #{dy}\n"
        end
      end
      str
    end
  end
end
