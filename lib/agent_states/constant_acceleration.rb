module BraveZealot
  module ConstantAccelerationStates

    @@current_accel = 0

    def ca
      @state = :ca

      #puts "ca - iteration"
      #puts "\ttank.vx, tank.vy = #{tank.vx}, #{tank.vy}"
      #puts "\ttank.status = #{@tank.status}"
      if @tank.status == 'dead'
        @@current_accel = 0
        angvel(0)
      else
        @@current_accel = @@current_accel + 0.001
      end

      speed(@@current_accel)
      angvel(@@current_accel)
    end
  end
end