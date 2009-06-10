module BraveZealot
  module ConstantVelocityStates
    def cv
      @state = :cv

      #puts "cv - iteration"
      #puts "\ttank.vx, tank.vy = #{tank.vx}, #{tank.vy}"
      speed(0.5)
      angvel(0)
    end
  end
end