module BraveZealot
  module SittingDuckStates
    def duck
      # do nothing
      @state = :duck
      speed(0)
      angvel(0)
    end
  end
end