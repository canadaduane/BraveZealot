module BraveZealot
  class Command
    GO_TO_FLAG = 1
    GO_HOME = 2

    def initialize(hq)
      @hq = hq
    end

    def create_flag_goal
      flag_goal = PfGroup.new
      flag_goal.add_obstacles(@hq.get_obstacles)
      flag_goal.add_rand(0.2)
      @hq.flags do |r|
        r.flags.each do |f|
          if ( f.color != @hq.our_color ) then
            flag_goal.add_goal(f.x, f.y,@hq.map.size)
            break
          end
        end
      end
      flag_goal
    end

    def create_home_base_goal
      base_goal = PfGroup.new
      base_goal.add_obstacles(@hq.get_obstacles)
      base_goal.add_goal(@hq.our_base.center.x, @hq.our_base.center.y, @hq.map.size)
      base_goal
    end
    
  end
end