bzrequire 'lib/collection/containers/priority_queue'

module Collection
  class PriorityQueue < Base
    def initialize
      @pq = Containers::PriorityQueue.new()
    end

    def insert(e)
      #we can just make sure that each Chunk can return a priority for us
      #we negate the priority so that we get a priority that returns the 'smallest' priority
      #first instead of the 'biggest' priority first
      @pq.push(e, -1*e.priority)
    end

    def remove
      @pq.pop
    end

    def size
      @pq.size
    end

    def empty?
      @pq.empty?
    end
  end
end