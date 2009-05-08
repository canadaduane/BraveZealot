bzrequire 'lib/communicator'
bzrequire 'lib/tank'

module BraveZealot
  class Headquarters < Communicator
    def start
      @bindings = {
        :hit_wall => []
      }
      @tanks = []
      mytanks do |r|
        r.mytanks.each do |t|
          @tanks << BraveZealot::DummyTank.new(self, t)
        end
        puts
      end
    end
    
    def bind(event, &block)
      if @bindings.keys.include?(event)
        @bindings[event] << block
      else
        raise "Unknown event: #{event}"
      end
    end
    
    def on_speed(r)
      if r.success?
        puts "Successfully changed speed (#{r.inspect})"
      else
        puts "Unable to change speed"
      end
    end
  end
end
