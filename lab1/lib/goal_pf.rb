require_relative 'move.rb'
module BraveZealot

  # A PotentialField Goal is a goal which suggests movements by calculating a
  # potential field.  This pf is a simple attraction/rejection field.
  class GoalPf

    # where is the center of the potential field?
    attr_accessor :origin_x, :origin_y, :factor, :radius

    # save the settings 
    def initialize(x,y,factor,radius)
      @origin_x = x
      @origin_y = y
      @factor = factor
      @radius = radius
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
      #print "current angle is #{current_angle}\n"
      #print "the goal angle is #{ang_g}\n";
      
      a = ang_g-current_angle
      #print "we need to move through #{a} radians\n"
      if ( a.abs() > Math::PI ) then
        a = -1*((2*Math::PI) - a)
        #print "how about we go the other way through #{a} radians?\n"
      end

      #this will need to be a more dynamic calculation but hopefully it gives us a good first try
      distance = distance*@factor
      #print "distance after factor = #{distance}\n"

      #we assume we will be updating every .1 seconds, so lets set speed and angvel to reach the desired destination in .5 seconds
      speed = distance*2
      angvel = a*2
      m = Move.new(speed, angvel)

      #and the final factor in our speed is based on how far off our desired angle we are
      speed = m.speed()*((Math::PI - a.abs()).abs() / Math::PI ) #we should never be turning more than pi
      #print "speed after angle factor = #{speed}\n"
      
      m = Move.new(speed, angvel)
      return m
    end


  end
end
