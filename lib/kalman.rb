require 'narray'

module BraveZealot
  module Kalman
    def self.included(base)
      base.module_eval do
        alias_method :observed_x,   :x   if base.method_defined?(:x)
        alias_method :observed_y,   :y   if base.method_defined?(:y)
        alias_method :observed_vx,  :vx  if base.method_defined?(:vx)
        alias_method :observed_vy,  :vy  if base.method_defined?(:vy)
        alias_method :observed_ax,  :ax  if base.method_defined?(:ax)
        alias_method :observed_ay,  :ay  if base.method_defined?(:ay)
        
        alias_method :observed_x=,  :x=  if base.method_defined?(:x=)
        alias_method :observed_y=,  :y=  if base.method_defined?(:y=)
        alias_method :observed_vx=, :vx= if base.method_defined?(:vx=)
        alias_method :observed_vy=, :vy= if base.method_defined?(:vy=)
        alias_method :observed_ax=, :ax= if base.method_defined?(:ax=)
        alias_method :observed_ay=, :ay= if base.method_defined?(:ay=)
        
        define_method(:x)  { @kalman_mu[0, 0] }
        define_method(:y)  { @kalman_mu[0, 3] }
        define_method(:vx) { @kalman_mu[0, 1] }
        define_method(:vy) { @kalman_mu[0, 4] }
        define_method(:ax) { @kalman_mu[0, 2] }
        define_method(:ay) { @kalman_mu[0, 5] }
      end
    end
    
    def kalman_initialize(mu = nil, sigma = nil, sigma_x = nil)
      # mean estimate (6 rows x 1 col matrix)
      @kalman_mu = mu || NMatrix.float(1, 6)
      
      # variance estimate 6x6 matrix
      @kalman_sigma = sigma || NMatrix.float(6, 6).diagonal([100, 0.1, 0.1, 100, 0.1, 0.1])
      
      # noise matrix
      @kalman_sigma_x = sigma_x || NMatrix.float(6, 6).diagonal([0.1, 0.1, 100, 0.1, 0.1, 100])
      
      # observation matrix
      @kalman_h = NMatrix.float(6, 2)
      @kalman_h[0, 0] = 1
      @kalman_h[3, 1] = 1
      
      @kalman_h_t = @kalman_h.transpose
      
      # covariance matrix
      @kalman_sigma_z = NMatrix.float(2, 2).diagonal(25)
      
      # Identity matrix
      @kalman_id = NMatrix.float(6, 6).diagonal(1)
    end
    
    def kalman_next(time)
      @last_time ||= 0.0
      dt = time - @last_time
      @last_time = time
      
      # Current observed position values
      z = NMatrix.float(1, 2)
      z[0, 0] = observed_x
      z[0, 1] = observed_y
      
      kalman_initialize if @kalman_mu.nil? or @kalman_sigma.nil?
      
      # re-used values
      f = kalman_transition_matrix(dt)
      fsum = f * @kalman_sigma * f.transpose + @kalman_sigma_x
      
      @kalman_k     = fsum * @kalman_h_t * (@kalman_h * fsum * @kalman_h_t + @kalman_sigma_z).inverse
      @kalman_sigma = (@kalman_id - @kalman_k * @kalman_h) * fsum
      @kalman_mu    = f * @kalman_mu + @kalman_k * (z - @kalman_h * f * @kalman_mu)
    end
    
    def kalman_predicted_mu(dt)
      f = kalman_transition_matrix(dt)
      f * @kalman_mu
    end
    
    def kalman_distribution
      sx = Math.sqrt(@kalman_sigma[0, 0])
      sy = Math.sqrt(@kalman_sigma[3, 3])
      rho = @kalman_sigma[3, 0] / (sx * sy)
      [x, y, sx, sy, rho]
    end
    
    def kalman_mu
      @kalman_mu
    end
    
    def kalman_sigma
      @kalman_sigma
    end

  protected
    
    def kalman_transition_matrix(dt, c = 0)
      f = NMatrix.float(6, 6).diagonal(1.0)
      f[1, 0] = dt
      f[2, 1] = dt
      f[4, 3] = dt
      f[5, 4] = dt
      f[2, 0] = 0.5 * dt ** 2
      f[5, 3] = 0.5 * dt ** 2
      f[1, 2] = -c
      f[4, 5] = -c
      f
    end
    
  end
end
