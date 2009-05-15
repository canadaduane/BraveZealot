bzrequire 'lib/agent/basic'
bzrequire 'lib/collection/stack'
bzrequire 'lib/collection/queue'
bzrequire 'lib/collection/priority_queue'
require 'set'

module BraveZealot
  module Agent
    class Search < Basic
      def to_gnuplot
        str = @hq.map.to_gnuplot
        last = nil
        s = @n
        if $options.debug then
          get_log.each do |n|
            if !last.nil?  then
              str += "set arrow from #{last.center.x}, #{last.center.y} to #{n.center.x}, #{n.center.y} nohead lt 5\n"
              str += "plot '-' with lines\n"
              str += " 0 0 0 0\n"
              str += "e\n"
              str += "pause 0.005000\n"
            end
            last = n
          end
        end
        #puts "Found solution with path #{s.predecessors.map{|n| n.to_coord.inspect }}->#{s.to_coord.inspect}"
        puts "Flag at #{@hq.map.goal.to_coord.inspect} -> Our solutions is #{s.to_coord.inspect} (#{s.actual_cost})"
        last = nil
        list = s.predecessors
        s.predecessors.each do |n|
          if !last.nil?  then
            str += "set arrow from #{last.center.x}, #{last.center.y} to #{n.center.x}, #{n.center.y} nohead lt 1\n"
            str += "plot '-' with lines\n"
            str += " 0 0 0 0\n"
            str += "e\n"
            str += "pause 0.005000\n"
          end
          last = n
        end
        str += "set arrow from #{last.center.x}, #{last.center.y} to #{s.center.x}, #{s.center.y} nohead lt 1\n"
        str += "plot '-' with lines\n"
        str += " 0 0 0 0\n"
        str += "e\n"
        str += "pause 0.005000\n"
        str
      end

      def log(n)
        @log ||= []
        @log << n
      end

      def get_log
        @log ||= []
      end
    end
    
    class UninformedSearch < Search
      def start
        init = @hq.map.chunk_at_point(@tank.x, @tank.y)
        fringe = Collection::Stack.new
        search(init, fringe)
      end
      
      protected
      
      def search(init, fringe)
        closed = Set.new
        fringe = fringe.insert(init)
        loop do
          return false if fringe.empty?
          node = fringe.remove
          log(node)
          return node if goal?(node)
          if !closed.include?(node)
            closed.add(node)
            fringe.insert_all(node.succ)
          end
        end
      end
      
      def goal?(chunk)
        @hq.map.goal?(chunk)
      end
    end

    class InformedSearch < Search
      def start
        init = @hq.map.chunk_at_point(@tank.x, @tank.y)
        fringe = Collection::PriorityQueue.new
        @n = search(init, fringe)
        
        f = File.new($options.gnuplot_file,'w')
        f.write(to_gnuplot)
        f.close
        puts "Finished!"
        $stdout.flush
      end

      def search(init, fringe)
        closed = Set.new
        fringe.insert(init)
        loop do
          return false if fringe.empty?
          node = fringe.remove
          return node if node.goal?
          if !closed.include?(node)
            log(node)
            closed.add(node)
            #this is where informed searches are different we must evaluate a priority before pushing onto the priority queue
            node.succ.each do |n|
              n2 = n.clone
              n2.g = node.g + (node.center.vector_to(n.center).length)
              n2.predecessors = ( node.predecessors.clone ) << node
              fringe.insert(n2)
            end
          end
        end
      end
    end

    class GreedyInformedSearch < InformedSearch
      def search(init, fringe)
        closed = Set.new
        fringe.insert(init)
        loop do
          return false if fringe.empty?
          node = fringe.remove
          return node if node.goal?
          if !closed.include?(node)
            log(node)
            closed.add(node)
            #this is where informed searches are different we must evaluate a priority before pushing onto the priority queue
            node.succ.each do |n|
              n2 = n.clone
              n2.predecessors = ( node.predecessors.clone ) << node
              fringe.insert(n2)
            end
          end
        end
      end
    end
  end
end

