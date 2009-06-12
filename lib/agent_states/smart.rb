module BraveZealot
  module SmartStates
    attr_accessor :path
    
    def smart
      @path = hq.map.search(@tank, @goal)
      @state = :smart_follow_path
    end
    
    def smart_follow_path
      # puts "in the smart state"
      @idx ||= 0
      unless goal_reached(8)#@goal
        
        # puts "Tank at: #{@tank.x}, #{@tank.y} Goal at: #{@goal.x}, #{@goal.y}"
        # new_path = check(:search, 1000* $options.refresh, @path, (@path.nil? or @path.empty?)){ hq.map.search(@tank, @goal) }
        #puts "I am done searching!!!"
        # @path = new_path || @path || []
        @group ||= PfGroup.new
        @dest ||= [@tank.x, @tank.y]
        
        if @path.size > 2
          refresh($options.refresh) do
            #puts "Calculating distance to #{@dest[0]},#{@dest[1]}"
            dist = Math::sqrt((@dest[0] - @tank.x)**2 + (@dest[1] - @tank.y)**2)
            #puts "I am #{dist} away from my next destinattion at #{@dest[0]},#{@dest[1]}"
            if dist < 25 then
              last = hq.map.array_to_world_coordinates(@path[0][0], @path[0][1])
              nex = hq.map.array_to_world_coordinates(@path[1][0], @path[1][1])
              difference = nex[0]-last[0],nex[1]-last[1]
              nex_idx = 1
              @path.each_with_index do |pos, idx|
                cand = hq.map.array_to_world_coordinates(pos[0],pos[1])
                cand_diff = cand[0]-nex[0],cand[1]-nex[1]
                if cand_diff[0] == difference[0] and cand_diff[1] == difference[1] then
                  nex = cand
                  nex_idx = idx
                else
                  break
                end
              end
              @path.slice!(0..(nex_idx-1))
              @group = PfGroup.new
              #puts "updating goal to be at #{nex[0]},#{nex[1]}"
              @group.add_field(Pf.new(nex[0], nex[1], hq.map.world_size, 5, 1))
              @dest = nex
            end
          end
        else
          #puts "Updating goal to be at the goal"
          @group = PfGroup.new
          @group.add_field(Pf.new(@goal.x, @goal.y, hq.map.world_size, 5, 0.5))
        end
        move = @group.suggest_move(@tank.x, @tank.y, @tank.angle)
        speed move.speed
        angvel move.angvel
      else
        @dest = nil
        @path = nil
        @idx = 0
        @group = nil
        puts "transitioning out of smart state because I reached #{@goal.inspect} I am at #{@tank.x},#{@tank.y}"
        transition(:smart, :smart_look_for_enemy_flag)
      end
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