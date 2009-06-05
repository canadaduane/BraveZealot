bzrequire 'lib/communicator'
bzrequire 'lib/agent'
module BraveZealot
  module HuntingStates
    #hunt the closest enemy tank
    def huntc
      refresh($options.refresh) do
        if @tank.shots_available == 0 then
          puts "Waiting for Ammo"
          return
        end
        angvel 0
        speed 0
        myc = @tank.to_coord
        @hunter_target = nil
        distance = 100000
        @hq.map.othertanks.each do |et|
          if et.alive? then
            dt = myc.vector_to(et.to_coord).length
            if ( dt < distance ) then
              distance = dt
              @hunter_target = et
            end
          end
        end

        unless @hunter_target.nil? then
          #@state = :hunter_target
          #puts "going to hunter_target mode: target = #{@target.inspect}"
          @state = :hunter_find_range
        end
      end
    end

    def hunter_target
      puts "trying to target enemy"
      #bullet velocity
      bv = 100.0

      #target velocity
      tv = Coord.new(0.1,0.1)
      #target position
      tp = @target.to_coord
      #target velocity overall
      tvo = Math.sqrt(tv.x**2 + tv.y**2)
      
      #my velocity
      mv = Coord.new(@tank.vx, @tank.vy)
      #my position
      mp = @tank.to_coord

      #expected target position in 1 second
      tpe = Coord.new(tp.x + tv.x, tp.y + tv.y) 

      #distance to expected position
      d = mp.vector_to(tpe).length

      #time for my bullet to arrive
      eta = d/100.0

      #perfect angle to shoot
      pas = Math.atan2(tpe.y - @tank.y, tpe.x - @tank.x)

      if pas < 0.0  then
        pas += 2*Math::PI
      elsif pas > (2*Math::PI) then
        pas -= 2*Math::PI
      end

      #difference of my angle and perfect angle
      diff = pas - @tank.angle
      if diff < -1 * Math::PI or diff > Math::PI then
        diff = @tank.angle - pas
      end

      puts " I have #{diff} radians to pass thru and #{eta} time for bullet travel"

      if ( diff.abs + eta ) < 1.0 then
        if ( diff < 0.0 ) then
          angvel -1
        else
          angvel 1
        end
        puts "going to take my shot - I am going to turn for #{diff} seconds and then wait #{1 - diff - eta} sec before I shoot"
        EventMachine::Timer.new(1 - diff - eta) do 
          shoot
        end
        @state = :hunter_wait
      end

      #otherwise get my angle closer to the perfect angle
      newangvel = diff / ($options.refresh)
      #set my angular velocity to get my angle correct in 2 refreshes
      angvel newangvel
      @state = :huntc
    end

    def hunter_wait
      sleep(1.0) do 
        @state = :huntc
      end
    end

    def hunter_find_range
      #these are the ranges we will check
      range_options = [0.25, 0.50, 0.75, 1.0, 1.25, 1.50, 1.75, 2.00]
      #bullet velocity
      bv = 100.0
      refresh($options.refresh) do
        range_options.each do |to|
          #expected position
          ep = @hunter_target.kalman_predicted_mu(to)
          puts "expected position after #{to}sec #{ep.inspect}"
          epc = Coord.new(ep[0], e[3])

          #figure out how long the bullet has to travel
          d = @tank.to_coord.vector_to(epc).length
          eta = d/bv

          #figure out how long we have to turn for
          diff = hunter_calc_diff(epc)
          ett = 2*diff #fudge factor meaning it will take us twice as long to get there as we think
          
          if (ett + eta) < to then
            @hunter_range = to
            @state = :hunter_hone_angle
            hunter_hone_angle
            return
          end
        end
      end
      @state = :huntc
    end

    def hunter_hone_angle
      #bullet velocity
      bv = 100.0
      refresh($options.refresh) do
        ep = @hunter_target.kalman_predicted_mu(@hunter_range)
        epc = Coord.new(ep[0], ep[3])

        d = @tank.to_coord.vector_to(epc).length
        eta = d/bv

        diff = hunter_calc_diff(epc)

        if diff < $options.refresh then
          angvel (diff.neg?)?-1:1
          EventMachine::Timer.new(diff) do 
            shoot
          end
        else
          if (eta + diff) > @range then
            
          else

          end
        end
      end
    end

    def hunter_wait_for_shot
      if @tank.shots_available == 0 then
        puts "no shots available - I must have fired"
        @state = :dummy_do_nothing
      end
    end

    def hunter_calc_diff(p)
      #perfect angle to shoot
      pas = Math.atan2(p.y - @tank.y, p.x - @tank.x)

      if pas < 0.0  then
        pas += 2*Math::PI
      elsif pas > (2*Math::PI) then
        pas -= 2*Math::PI
      end

      #difference of my angle and perfect angle
      diff = pas - @tank.angle
      if diff < -1 * Math::PI or diff > Math::PI then
        diff = @tank.angle - pas
      end
    end
  end
end