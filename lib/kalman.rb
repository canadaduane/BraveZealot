require 'narray'

module BraveZealot
  module Kalman
    
    def kalman_transition_matrix(t, c = 0)
      f = NMatrix.float(6, 6).diagonal(1.0)
      f[1, 0] = t
      f[2, 1] = t
      f[4, 3] = t
      f[5, 4] = t
      f[2, 0] = 0.5 * t ** 2
      f[5, 3] = 0.5 * t ** 2
      f[1, 2] = -c
      f[4, 5] = -c
      f
    end
    
    def kalman_initialize(mu = nil, sigma = nil, sigma_x = nil)
      # mean estimate 6x1 matrix
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
    
    def kalman_next_state(x, y, t = 1.0)
      # Current observed position values
      z = NMatrix.new('float', x, y).reshape(1, 2)
      
      # re-used values
      f = kalman_transition_matrix(t)
      fsum = f * @kalman_sigma * f.transpose + @kalman_sigma_x
      
      @kalman_k     = fsum * @kalman_h_t * (@kalman_h * fsum * @kalman_h_t + @kalman_sigma_z).inverse
      @kalman_sigma = (@kalman_id - @kalman_k * @kalman_h) * fsum
      @kalman_mu    = f * @kalman_mu + @kalman_k * (z - @kalman_h * f * @kalman_mu)
    end
    
    def kalman_predicted_mu(t)
      f = kalman_transition_matrix(t)
      f * @kalman_mu
    end
    
  end
end
