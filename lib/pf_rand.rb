bzrequire 'lib/move.rb'

module BraveZealot

  # A PotentialField Goal with a randmon potential field
  class PfRand

    # where is the center of the potential field?
    attr_accessor :factor

    # save the settings 
    def initialize(factor)
      @factor = factor
    end

    def suggestDelta(current_x, current_y)
      return []
    end

    # suggest a move - Totally random
    def suggestMove(current_x, current_y, current_angle)
      speed = ( (rand() *2) - 1) * @factor
      angvel = ( (rand() *2) -1)  * @factor
      m = Move.new(speed, angvel)
      return m
    end
  end
end
