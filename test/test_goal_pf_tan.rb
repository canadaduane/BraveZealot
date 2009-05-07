#include dependencies
require 'test/unit'
require 'shoulda'
require_relative '../lib/goal_pf_tan.rb'

module BraveZealot
  class TestGoalPfTan < Test::Unit::TestCase
    context "to the right of the goal" do
      setup do
        @g = GoalPfTan.new(0,0,1,0)
      end
      should "point up" do
        distance,angle = @g.suggestDistanceAngle(100,0)
        assert_equal(distance,100)
        assert_equal(angle, Math::PI/2)
      end
    end
    context "to the left of the goal" do
      setup do
        @g = GoalPfTan.new(0,0,1,0)
      end
      should "point down" do
        distance,angle = @g.suggestDistanceAngle(-100,0)
        assert_equal(distance,100)
        assert_equal(3*Math::PI/2,angle)
      end
    end
    context "above the goal" do
      setup do
        @g = GoalPfTan.new(0,0,1,0)
      end
      should "point left" do
        distance,angle = @g.suggestDistanceAngle(0,100)
        assert_equal(distance,100)
        assert_equal(angle, Math::PI)
      end
    end
    context "below the goal" do
      setup do
        @g = GoalPfTan.new(0,0,1,0)
      end
      should "point right" do
        distance,angle = @g.suggestDistanceAngle(0,-100)
        assert_equal(distance,100)
        assert_equal(angle, 0)
      end
    end
  end
end
