module BraveZealot
  module AssassinateStates
    def assassinate
      periodically(0.5) do
        shoot
        if @target_tank.status != "normal"
          cancel_timers
          transition(:assassinate, :assassinate_done)
        end
      end
      @goal = @target_tank
      seek
    end
    
    def assassinate_done
      transition(:assassinate_done, :wait)
    end
  end
end