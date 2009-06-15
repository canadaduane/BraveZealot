module BraveZealot
  module AssassinStates
    def assassin
      periodically(0.3) do
        shoot
        if @target_tank.status != "normal"
          cancel_timers
          transition(:assassin, :assassin_mission_accomplished)
        end
      end
      @goal = @target_tank
      seek
    end
    
    def assassin_mission_accomplished
      transition(:assassin_mission_accomplished, :dummy)
    end
  end
end