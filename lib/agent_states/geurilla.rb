module BraveZealot
  module GeurillaStates
    def geurilla_take_cover
      shadows = @map.shadows(0.5)
      
      pos = @map.world_to_array_coordinates(@tank.x,@tank.y)

      
    end

    def geurilla_go_to_other_side
      @goal = hq.map.random_spot
      @state = :seek
    end
  end
end