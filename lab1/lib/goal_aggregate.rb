module BraveZealot

  # An Aggregate Goal is made up of sub goals which are averaged together to
  # make decisions about suggested actions
  class GoalAggregate

    attr_accessor :goals

    def initialize()
      @goals = []
    end

    def addGoal(g)
      @goals << g
    end

    # suggest a move
    def suggestMove(current_x, current_y, current_angle)
      speed = 0
      angvel = 0
      index = 0
      @goals.each() do |g|
        index++
        m = g.suggestMove(current_x, current_y, current_angle)
        speed += m.speed
        angvel += m.angvel
      end

      if index > 0 then
        m = Move.new(speed/index, angvel/index)
      else
        m = Move.new(0,0)
      end
      return m
    end

  end

end
