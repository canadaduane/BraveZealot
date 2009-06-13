module BraveZealot
  module SmartStates
    attr_accessor :path
    
    def smart
      # hq.periodic_action(2.5, 5) do
        @path = hq.map.search(@tank, @goal)
      # end
      # transition(:smart, :smart_follow_path)
      smart_follow_path
    end
    
    def smart_follow_path
      if @path.nil?
        @state = :smart
        return
      end
      
      @waypoint ||= @path.first || @tank
      
      # parts = @path[0..10].size
      # avg = @path[0..10].inject(0.0){ |sum, coord| sum + @tank.vector_to(coord).length } / parts
      # puts "Here: #{@tank.x}, #{@tank.y}"
      # puts "Average dist from here: #{avg}"
      
      distance = @tank.vector_to(@waypoint).length
      while !@path.empty? and distance < 30
        @waypoint = @path.shift
        distance = @tank.vector_to(@waypoint).length
      end 
      
      group = PfGroup.new
      group.add_field(Pf.new(@waypoint.x, @waypoint.y, hq.map.world_size, 5, 1))
      move = group.suggest_move(@tank.x, @tank.y, @tank.angle)
      
      speed move.speed
      angvel move.angvel
      
      transition(:smart_follow_path, :smart_look_for_enemy_flag) if @path.empty?
    end
    
    def smart_look_for_enemy_flag
      if hq.enemy_flag_exists?
        puts "Enemy flags:"
        p hq.enemy_flags
        @goal = hq.enemy_flags.randomly_pick(1).first
        @state = :smart
      else
        # Remain in :smart_look_for_enemy_flag state otherwise
      end
    end
    
    def smart_return_home
      puts "Going into the the smart_return_home state..."
      @goal = hq.my_base.center
      puts "goal at #{@goal.inspect}, path=#{@path}, idx=#{@idx}, dest=#{@dest}, group=#{@group}"
      push_next_state(:smart, :dummy)
      @state = :smart
    end
  end
  
end