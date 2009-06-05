bzrequire 'lib/communicator'
bzrequire 'lib/agent'
module BraveZealot
  module HuntingStates
    #hunt the closest enemy tank
    def huntc
      angvel 0
      speed 0
      puts "in huntc"
      myc = @tank.to_coord
      @target = nil
      distance = 100000
      @hq.map.othertanks.each do |et|
        dt = myc.vector_to(et.to_coord).length
        if ( dt < distance ) then
          distance = dt
          @target = et
        end
      end

      unless @target.nil? then
        @state = :hunter_target
        puts "going to hunter_target mode: target = #{@target.inspect}"
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
  end
end