module BraveZealot
  module GaussianAccelerationStates

    current_accel = 0


    def ga
      @state = :ga_run
      @E = 2.71828182845904523536
      @a = 1.0
      @b = 0.0
      @c = 1.0
    end

    def ga_run
      # this needs to be done..

      x = rand(200)
      #puts "rand = #{x}"
      x = (x - 100) / 100.0
      #puts "x = #{x}"

      # function pulled from:
      # http://en.wikipedia.org/wiki/Gaussian_function
      gf = (@a * @E) * - ((x - @b)**2 / (2 * @c**2))
      #puts "gf = #{gf}"
      speed(-1 * gf)
      angvel(rand_sign() * gf)
    end

    def rand_sign()
      if rand(2) == 1
        return 1
      else
        return -1
      end
    end
  end
end