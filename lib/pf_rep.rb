bzrequire('lib/pf.rb')

module BraveZealot
  class PfRep < Pf
    # suggest a distance and angle
    def suggest_delta(current_x, current_y)
      x_dis = @origin_x - current_x
      y_dis = @origin_y - current_y
      distance = Math.sqrt((x_dis)**2 + (y_dis)**2)

      ang_g = Math.atan2(y_dis,x_dis)
      
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
  end
end
