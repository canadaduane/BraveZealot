module BraveZealot
  module WildStates

    # algorithm description
    # ways to fool the filter..
    #
    # random period of time
    # random acceleration
    # random angle/direction


    def wild
      @state = :wild_run
      @speed_timer = 1
      @angvel_timer = 1
      @max_period = 25.0
    end

    def wild_run
      @speed_timer -= 1
      @angvel_timer -= 1
      
      if @speed_timer == 0
        @speed_timer = rand(@max_period.to_i) + 1
        velocity = (rand(2 * @max_period.to_i) - @max_period) / @max_period
        speed(velocity)
        puts "speed_timer, velocity = #{@speed_timer}, #{velocity}"
      end

      if @angvel_timer == 0
        @angvel_timer = rand(@max_period.to_i) + 1
        angular_velocity = (rand(2 * @max_period.to_i) - @max_period) / @max_period
        angvel(angular_velocity)
        puts "angvel_timer, angular_velocity = #{@angvel_timer}, #{angular_velocity}"
      end
    end
  end
end