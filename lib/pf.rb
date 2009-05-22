bzrequire 'lib/move.rb'

module BraveZealot

  # A PotentialField Goal is a goal which suggests movements by calculating a
  # potential field.  This pf is a simple attraction/rejection field.
  class Pf

    MAX = 25

    # where is the center of the potential field?
    attr_accessor :origin_x, :origin_y, :spread, :radius, :alpha

    # save the settings 
    def initialize(x,y,spread,radius, alpha)
      @origin_x = x
      @origin_y = y
      @spread = spread
      @radius = radius
      @alpha = alpha
    end

    # suggest a distance and angle
    def suggest_delta(current_x, current_y)
      x_dis = @origin_x - current_x
      y_dis = @origin_y - current_y
      distance = Math.sqrt((x_dis)**2 + (y_dis)**2)

      ang_g = Math.atan2(y_dis,x_dis)    
      #if ( ang_g < 0 ) then
      #  ang_g = ang_g + Math::PI*2
      #end
      puts "distance = #{distance}"
      if ( distance < @radius ) then
        puts "inside the radius!"
        return [0,0]
      elsif ( distance < (@spread + @radius)) then
        dx = @alpha*(distance-@radius)*Math.cos(ang_g)
        dy = @alpha*(distance-@radius)*Math.sin(ang_g)
      else
        dx = @alpha*@spread*Math.cos(ang_g)
        dy = @alpha*@spread*Math.sin(ang_g)
      end
      
      if distance < 40 then
        dx = dx
        dy = dy
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
      [dx, dy]
    end

    # suggest a move
    def suggest_move(current_x, current_y, current_angle)
      dx,dy = suggest_delta(current_x,current_y)
      #print "current angle is #{current_angle}\n"
      #print "the goal angle is #{ang_g}\n";
      ang_g = Math.atan2(dy,dx)
      distance = Math.sqrt(dx**2 + dy**2)

      a = ang_g-current_angle
      #print "we need to move through #{a} radians\n"
      if ( a.abs() > Math::PI ) then
        a = -1*((2*Math::PI) - a)
        #print "how about we go the other way through #{a} radians?\n"
      end

      # This will need to be a more dynamic calculation but hopefully it
      # gives us a good first try
      distance = distance*@factor

      # We assume we will be updating every .1 seconds, so lets set speed and
      # angvel to reach the desired destination in .5 seconds
      speed = distance*2
      angvel = a*2
      m = Move.new(speed, angvel)

      # If we don't need to move, then lets not spin
      if ( speed == 0 ) then
        angvel = 0
      end

      # And the final factor in our speed is based on how far off our
      # desired angle we are
      speed = m.speed()*((Math::PI - a.abs()).abs() / Math::PI ) #we should never be turning more than pi
      
      m = Move.new(speed, angvel)
      return m
    end


  end
end
