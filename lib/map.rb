bzrequire 'lib/obstacle.rb'
bzrequire 'lib/indent'

require 'pdf/writer'

module BraveZealot
  class Map
    attr_accessor :world_size, :bases, :obstacles, :flags
    attr_accessor :mytanks, :othertanks
    
    def initialize(world_size)
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
      options.each_pair do |key, items|
        puts "Draw #{key} #{items.size}"
        items.each do |i|
          i.to_pdf(pdf, options) if i.respond_to?(:to_pdf)
        end if items
      end
      
      yield pdf if block_given?
      
      # Draw surrounding wall
      pdf.stroke_style(PDF::Writer::StrokeStyle.new(1))
      pdf.stroke_color Color::RGB::Black
      pdf.rectangle(-400, -400, 800, 800).close_stroke
      
      pdf
    end
  end
  
end