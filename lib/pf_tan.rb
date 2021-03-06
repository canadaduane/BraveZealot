bzrequire 'lib/move.rb'

module BraveZealot

  # A PotentialField Goal is a goal which suggests movements by calculating a
  # potential field.  This pf is a simple attraction/rejection field.
  class PfTan

    # where is the center of the potential field?
    attr_accessor :origin_x, :origin_y, :spread, :radius, :alpha

    # save the settings 
    def initialize(x,y,spread,radius,alpha)
      @origin_x = x
      @origin_y = y
      @spread = spread
      @radius = radius
      @alpha = alpha
    end

    # get the goal distance and angle based on the current position
    def suggest_delta(current_x,current_y)
      x_dis = @origin_x - current_x
      y_dis = @origin_y - current_y
      distance = Math.sqrt((x_dis)**2 + (y_dis)**2)

      ang_g = (Math.atan2(y_dis,x_dis) - (Math::PI/2))

      if ( distance < @radius ) then
        return [0,0]
      elsif ( distance < (@spread + @radius)) then
        dx = -@alpha*(@spread+@radius-distance)*Math.cos(ang_g)
        dy = -@alpha*(@spread+@radius-distance)*Math.sin(ang_g)
      else
        return [0,0]
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

      #this will need to be a more dynamic calculation but hopefully it gives
      # us a good first try
      distance = distance*@factor
      #print "distance after factor = #{distance}\n"

      # We assume we will be updating every .1 seconds, so lets set speed and
      # angvel to reach the desired destination in .5 seconds
      speed = distance*2
      angvel = a*2
      m = Move.new(speed, angvel)

      #if we don't need to move, then lets not spin
      if ( speed == 0 ) then
        angvel = 0
      end

      # And the final factor in our speed is based on how far off our desired
      # angle we are (Note: we should never be turning more than pi)
      speed = m.speed()*((Math::PI - a.abs()).abs() / Math::PI )
      #print "speed after angle factor = #{speed}\n"
      
      m = Move.new(speed, angvel)
      return m
    end
  end
end
