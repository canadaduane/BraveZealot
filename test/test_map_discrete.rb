require(File.join(File.dirname(__FILE__), "helper"))
bzrequire 'lib/map_discrete'

class TestMapDiscrete < Test::Unit::TestCase
  def test_map
    map = MapDiscrete.new(10)
  end
end