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
      addField(PfRand.new(0.15)) if random_background
    end

    def addField(f)
      @fields << f
    end
    
    def addMapFields(map)
      max = map.size / 2
      # Add repulsion fields at corners of map
      #addField(PfRep.new(-max, -max, max/3, 0, 0.06))
      #addField(PfRep.new(-max, max, max/3, 0, 0.06))
      #addField(PfRep.new(max, -max, max/3, 0, 0.06))
      #addField(PfRep.new(max, max, max/3, 0, 0.06))
      #addField(PfRep.new(-max,0,max/3,0,0.06))
      #addField(PfRep.new(0,max,max/3,0,0.06))
      #addField(PfRep.new(max,0,max/3,0,0.06))
      #addField(PfRep.new(0,-max,max/3,0,0.06))

      # Next we add attraction fields for the goals
      map.flags.each do |f|
        addField(Pf.new(f.x, f.y, map.size, 0, 0.1))
      end

      # Next we add repulsion fields on all the vertices of all the obstacles
      map.obstacles.each do |o|
        #also add a tangential field at the center of each object
        addField(PfTan.new(o.center.x, o.center.y, o.side_length/2, o.side_length/2, 0.05))
        addField(PfRep.new(o.center.x, o.center.y, o.side_length, 0, 0.2))
      end

      # Add a random background noise field
      addField(PfRand.new(0.01))
      
    end
    
    def add_rand(factor)
        addField(PfRand.new(factor))
    end

    def add_goal(x, y, size)
      addField(Pf.new(x, y, size, 0, 0.1))
    end
    
    def add_obstacles(obstacles)
      obstacles.each do |o|
        addField(PfTan.new(o.center.x, o.center.y, o.side_length/2, o.side_length/2, 0.05))
        addField(PfRep.new(o.center.x, o.center.y, o.side_length, 0, 0.2))
      end
    end
    
    # suggest a distance and angle
    def suggestDelta(current_x, current_y)
      dx = 0.0
      dy = 0.0
      @fields.each do |f|
        fdx, fdy = f.suggestDelta(current_x, current_y)
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
    def suggestMove(current_x, current_y, current_angle)
      dx,dy = suggestDelta(current_x,current_y)
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

      #this will need to be a more dynamic calculation but hopefully it gives us a good first try
      # distance = distance*@factor
      #print "distance after factor = #{distance}\n"

      #we assume we will be updating every .1 seconds, so lets set speed and angvel to reach the desired destination in .5 seconds
      speed = distance/(5*SmartTank::REFRESH_RATE*25)
      angvel = a/(5*SmartTank::REFRESH_RATE)
      m = Move.new(speed, angvel)

      #if we don't need to move, then lets not spin
      if ( speed == 0 ) then
        angvel = 0
      end

      #and the final factor in our speed is based on how far off our desired angle we are
      speed = m.speed()*((((Math::PI - a.abs()).abs())) / Math::PI ) #we should never be turning more than pi
      #print "speed=#{speed} angvel=#{angvel}\n"
      
      m = Move.new(speed, angvel)
      return m
    end
    
  end
end
