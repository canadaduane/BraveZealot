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

    ang_g = Math.atan2(y_dis/x_dis)    
    ang_c = current_angle + (2* Math::PI)

    ap = ang_g - current_angle #how far off in the positive direction are we?
    an = ang_c - ang_g #how far off in the negative direction are we?
    
    #set the angle we need to travel through
    if ( ap >= an ) then
      a = ap
    else 
      a = -an
    end
    
    #this will need to be a more dynamic calculation but hopefully it gives us a good first try
    a = a*@factor
    distance = distance*@factor

    #and the final factor in our speed is based on how far off our desired angle we are
    distance = distance*((Math::PI - a.abs()) / Math::PI ) #we should never be turning more than pi
  
    #we assume we will be updating every .1 seconds, so lets set speed and angvel to reach the desired destination in .2 seconds
    speed = distance/0.2
    angvel = a/0.2
    m = Move.new(speed, angvel)

    return m
  end


end
