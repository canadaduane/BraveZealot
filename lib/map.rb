bzrequire 'lib/obstacle.rb'
bzrequire 'lib/indent'

require 'pdf/writer'

module BraveZealot
  class Map
    attr_accessor :world_size, :bases, :obstacles, :flags
    attr_accessor :mytanks, :othertanks, :my_color
    
    def initialize(world_size, my_color)
      @my_color = my_color
      raise ArgumentError, "World size cannot be nil or zero" if world_size.nil? or world_size == 0
      @world_size = world_size
      @bases      = []
      @obstacles  = []
      @flags      = []
      @mytanks    = []
      @othertanks = []
    end
    
    def world_x_min
      @world_x_min ||= -@world_size / 2
    end
    
    def world_x_max
      @world_x_max ||=  @world_size / 2
    end
    
    def world_y_min
      @world_y_min ||= -@world_size / 2
    end
    
    def world_y_max
      @world_y_max ||=  @world_size / 2
    end
    
    def to_pdf(pdf = nil, options = {})
      options = {
        :obstacles  => obstacles,
        :flags      => flags,
        :bases      => bases,
        :mytanks    => mytanks,
        :othertanks => othertanks
      }.merge(options)
      
      pdf ||= PDF::Writer.new(:paper =>
                [world_x_min - 50, world_y_min - 50,
                 world_x_max + 50, world_y_max + 50])
      
      # Draw optional map parts
      [:bases, :obstacles, :othertanks, :mytanks, :flags].each do |key|
        items = options[key]
        # puts "Draw #{key} #{items.size}"
        items.each do |i|
          i.to_pdf(pdf, options) if i.respond_to?(:to_pdf)
        end if items
      end
      
      if options.has_key?(:distributions)
        pdf.stroke_style(PDF::Writer::StrokeStyle.new(3))
        pdf.stroke_color(Color::RGB.from_fraction(0.8, 0.3, 0.1))
        options[:distributions].each do |x, y, sx, sy, rho|
          pdf.ellipse_at(x, y, sx, sy).stroke
        end if options[:distributions].is_a?(Array)
      end
      
      yield pdf if block_given?
      
      # Draw surrounding wall
      pdf.stroke_style(PDF::Writer::StrokeStyle.new(1))
      pdf.stroke_color Color::RGB::Black
      pdf.rectangle(-400, -400, 800, 800).close_stroke
      
      pdf
    end
    
    def get_othertank(callsign)
      @othertanks.find{ |t| t.callsign == callsign }
    end
    
    def observe_othertanks(response)
      if @othertanks.empty?
        @othertanks = response.othertanks
        @othertanks.each do |tank|
          tank.kalman_initialize
        end
      else
        response.othertanks.each do |src_tank|
          unless (dst_tank = get_othertank(src_tank.callsign)).nil?
            dst_tank.observed_x = src_tank.observed_x
            dst_tank.observed_y = src_tank.observed_y
            dst_tank.kalman_next(response.time)
          end
        end
      end
    end
    
    #make an observation about mytanks
    def observe_mytanks(r)
      if @mytanks.empty? then
        @mytanks = r.mytanks
        @mytanks.each do |my|
          my_mu = NMatrix.float(1, 6).fill(0.0)
          my_mu[0] = my_base.center.x
          my_mu[3] = my_base.center.y
          my.kalman_initialize(my_mu)
        end
      else
        if @mytanks.size != r.mytanks.size then
          raise ArgumentError, "list of mytanks from response object is different size #{r.mytanks.size} than my list #{@mytanks.size}"
        end

        @mytanks.each_with_index do |my, idx|
          my.observed_x = r.mytanks[idx].observed_x
          my.observed_y = r.mytanks[idx].observed_y
          my.kalman_next(r.time)
        end
      end
    end
    
    def my_base
      if @my_base.nil? then
        bases.each do |b|
          if b.color == my_color then
            @my_base = b
          end
        end
      end
      @my_base
    end
  end
end