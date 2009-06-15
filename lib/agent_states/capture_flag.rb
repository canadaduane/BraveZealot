module BraveZealot
  module CaptureFlagStates
    def capture_flag
      if hq.enemy_flag_exists?
        @goal = hq.enemy_flags.randomly_pick(1).first
        puts "Seeking enemy flag: #{@goal.color} at (#{@goal.x}, #{@goal.y})"
        push_next_state(:seek_done, :capture_flag_home)
        transition(:capture_flag, :seek)
      else
        # Remain in :smart_look_for_enemy_flag state otherwise
      end
    end
    
    def capture_flag_home
      @goal = hq.my_base.center
      puts "Seeking home base: (#{@goal.x}, #{@goal.y})"
      push_next_state(:seek_done, :capture_flag_done)
      transition(:capture_flag_home, :seek)
    end
    
    def capture_flag_done
      transition(:capture_flag_done, :wait)
    end
    
  end
end