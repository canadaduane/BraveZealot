bzrequire 'lib/kalman'
bzrequire 'lib/xy_methods'
bzrequire 'lib/vector'

module BraveZealot
  class Coord
    attr_accessor :x, :y
    
    include Kalman
    include XYMethods
    
    alias :pre_kalman_initialize :kalman_initialize
    def kalman_initialize(mu = nil, sigma = nil, sigma_x = nil)
      sigma ||= NMatrix.float(6, 6).diagonal([400, 0.0, 0.0, 400, 0.0, 0.0])
      sigma_x ||= NMatrix.float(6, 6).diagonal([0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
      pre_kalman_initialize(mu, sigma, sigma_x)
    end
    
    def initialize(x, y)
      @x = x.to_f
      @y = y.to_f
    end
    
    def inspect
      "(#{x}, #{y})"
    end
  end
end