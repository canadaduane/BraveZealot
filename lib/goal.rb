bzrequire 'lib/move.rb'

module BraveZealot

  # A Goal suggests actions for a Tank
  class Goal

    # All Goals should be able to specify which direction we should move
    # based on our current position
    def suggest_move(current_x, current_y, current_angle)
      return Move.new(0,0)
    end
   
  end

end
