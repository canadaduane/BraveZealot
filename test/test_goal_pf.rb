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
        assert_equal(m.speed(),0.0)
        m = @g.suggestMove(0,0,Math::PI)
        assert_equal(m.speed(),0.0)
      end
      should "suggest an angvel of 0" do
        m = @g.suggestMove(0,0,0)
        assert_equal(m.angvel(),0,0)
      end
    end
  end
end
