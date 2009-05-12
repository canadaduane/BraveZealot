bzrequire 'lib/communicator'
bzrequire 'lib/tank'
bzrequire 'lib/map'

module BraveZealot
  class Headquarters < Communicator
    attr_reader :map, :my_color, :my_base, :mytanks_time
    
    class MissingData < Exception; end
    
    def start
      @tanks = []                 # Current BraveZealot::Tank objects
      @world_time = 0.0           # Last communicated world time
      @message_times = {}         # Last time we received a message (in Time.now units)
      
      # Gather initial world data... which team are we?  how big is the map?
      constants do |r|
        world_size = nil
        r.constants.each do |c|
          case c.name
          when 'team'      then @my_color = c.value
          when 'worldsize' then world_size = c.value.to_f
          end
        end
        
        @map = BraveZealot::Map.new(world_size)
        
        refresh(:bases) do
          refresh(:obstacles) do
            refresh(:flags) do
              # Initialize each of our tanks
              mytanks do |r|
                #generate potential field plots
                # flag_goal = @command.create_flag_goal
                # base_goal = @command.create_home_base_goal
                # 
                flag_file = File.new('flag.gpi', 'w')
                flag_file.write(@map.to_gnuplot(create_flag_goal))
                flag_file.close
                # 
                # base_file = File.new('base.gpi','w')
                # base_file.write(@map.to_gnuplot(create_home_base_goal))
                # base_file.close

                r.mytanks.each do |t|
                  tank =
                    case $options.brain
                    when 'dummy' then BraveZealot::DummyTank.new(self, t)
                    when 'smart' then BraveZealot::SmartTank.new(self, t)
                    end
                  tank.goal = create_flag_goal
                  tank.mode = :capture_flag
                  @tanks[t.index] = tank
                end
              end
            end
          end
        end
      end
      
      
      EventMachine::PeriodicTimer.new(0.5) do
        if flag_possession?
          @tanks.each_with_index do |t, i|
            if t.mode != :home then
               puts "changing tank #{i} to goal :home"
              t.goal = create_home_base_goal
              t.mode = :home
            end
          end
        else
          @tanks.each_with_index do |t, i|
            if t.mode != :capture_flag then
              puts "changing tank #{i} to goal :capture_flag"
              t.goal = create_flag_goal
              t.mode = :capture_flag
            end
          end
        end
      end
      
    end
    
    # Returns true if any of our tanks possesses an enemy flag
    def flag_possession?
      @tanks.any? do |t|
        #puts "t.tank.flag = #{t.tank.flag}"
        t.tank.flag != "none" &&
        t.tank.flag != @my_color
      end
    end
    
    def create_flag_goal
      flag_goal = PfGroup.new
      p @map
      flag_goal.add_obstacles(@map.obstacles)
      refresh(:flags, 0.5) do
        enemy_flags = @map.flags.select{ |f| f.color != @my_color }
        flag_goal.add_goal(enemy_flags.first.x, enemy_flags.first.y, @map.size) unless enemy_flags.empty?
      end
      flag_goal
    end
    
    def create_home_base_goal
      base_goal = PfGroup.new
      base_goal.add_obstacles(@map.obstacles)
      base_goal.add_goal(@my_base.center.x, @my_base.center.y, @map.size)
      base_goal
    end
    
    # Note: estimate_world_time may be non-continuous because @world_time is
    # updated sporadically.
    def estimate_world_time
      delta = Time.now - @clock
      @world_time + delta
    end
    
    def message_time(command)
      @message_times[command.to_sym] || 0.0
    end
    
    # Catch-all callback, called on EVERY message to EVERY tank
    def on_any(r)
      @clock = Time.now
      @world_time = r.time
      @message_times[r.command.to_sym] = r.time
      #p r; puts
    end
    
    # If our most recent data is older than 'freshness', call command and get
    # more current info.  Otherwise, just assume our data is good enough and
    # call the passed-in block.
    def refresh(command, freshness = 0.0, &block)
      if (estimate_world_time - message_time(command)) > freshness
        # Note: Because global callbacks occur before local, on_* will
        # have a chance to update data before the following block.call
        ignore_arg = Proc.new { |r| block.call if block }
        send(command, &ignore_arg)
      else
        block.call if block
      end
    end
    
    def on_mytanks(r)
      r.mytanks.each do |t|
        @tanks[t.index].tank = t if @tanks.size > t.index
      end
    end
    
    def on_flags(r)
      @map.flags = r.flags
    end
    
    def on_bases(r)
      p r
      @map.bases = r.bases
      @my_base = @map.bases.find{ |b| b.color = @my_color }
    end
    
    def on_obstacles(r)
      @map.obstacles = r.obstacles
    end
  end
end
