module BraveZealot

  # A PotentialField Goal is a goal which suggests movements by calculating a
  # potential field.  This pf is a simple attraction/rejection field.
  class GoalPf

    # where is the center of the potential field?
    attr_accessor :origin_x, :origin_y, :factor

    # 
    def initialize(x,y,factor)
      @origin_x = x
      @origin_y = y
      @factor = factor
    end

    # suggest a move
    def suggestMove(current_x, current_y, current_angle)
      x_dis = @origin_x - current_x
      y_dis = @origin_y - current_y
      distance = Math.sqrt((x_dis)**2 + (y_dis)**2)

      ang_g = Math.atan2(y_dis,x_dis)    
      if ( ang_g < 0 ) then
        ang_g = ang_g + Math::PI*2
      end
      print "current angle is #{current_angle}\n"
      print "the goal angle is #{ang_g}\n";
      
      a = (current_angle + 2*Math::PI) - ang_g
      if ( a > Math::PI ) then
        a = (2*Math::PI) - a
      end
      print "angle we need to move through = #{a}\n"

      #and the final factor in our speed is based on how far off our desired angle we are
      distance = distance*((Math::PI - a.abs()).abs() / Math::PI ) #we should never be turning more than pi
      print "distance after angle factor = #{distance}\n"
      
      #this will need to be a more dynamic calculation but hopefully it gives us a good first try
      a = a*@factor
      print "angle after factor = #{a}\n"
      distance = distance*@factor
      print "distance after factor = #{distance}\n"
    
      #we assume we will be updating every .1 seconds, so lets set speed and angvel to reach the desired destination in .5 seconds
      speed = distance/0.5
      angvel = a/0.5
      m = Move.new(speed, angvel)

      return m
    end


  end
end
