module BraveZealot

  # The move class encapsulates the idea and data necessary
  # to change the speed and angle of a tank
  class Move
    attr_accessor :speed, :angvel

    def initialize(speed, angvel)
      #set the speed between -1 and 1    
      if ( speed > 1 ) then
        @speed = 1;
      elsif (speed < -1 ) then
        @speed = -1;
      else
        @speed = speed;
      end
      
      #set the angvel between -1 and 1
      if ( angvel > 1 ) then
        @angvel = 1
      elsif ( angvel < -1 ) then
        @angvel = -1
      else
        @angvel = angvel;
      end

    end

  end

end
