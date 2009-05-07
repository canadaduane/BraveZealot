#include dependencies
require 'test/unit'
require 'shoulda'
require_relative '../lib/goal_pf.rb'

module BraveZealot
  class TestGoalPf < Test::Unit::TestCase
    context "on top of goal" do
      setup do
        @g = GoalPf.new(0,0,1,0)
      end
      should "suggest a speed of 0" do
        m = @g.suggestMove(0,0,0)
        assert_equal(0.0,m.speed())

        m = @g.suggestMove(0,0,Math::PI)
        assert_equal(0.0,m.speed())
      end
      should "suggest an angvel of 0" do
        m = @g.suggestMove(0,0,0)
        assert_equal(0.0,m.angvel())

        m = @g.suggestMove(0,0,Math::PI)
        assert_equal(0.0,m.angvel())
      end
    end

    context "to the right of the goal facing up" do
      setup do
        @g = GoalPf.new(0,0,1,0)
      end
      should "suggest a speed of .75" do
        m = @g.suggestMove(100,0,Math::PI/2)
        assert_equal(0.75, m.speed())
      end
      should "suggest an angvel of 1" do
        m = @g.suggestMove(100,0,Math::PI/2)
        assert_equal(1,m.angvel())
      end
    end
  end
end
