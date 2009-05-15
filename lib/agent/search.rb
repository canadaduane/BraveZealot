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
        puts "Flag at #{@hq.map.goal.to_coord.inspect} -> Our solution is #{s.to_coord.inspect} (#{s.actual_cost} -> #{s.predecessors.size + 1}) Nodes popped: #{get_log.size}"
        last = s
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
        # str += "set arrow from #{last.center.x}, #{last.center.y} to #{s.center.x}, #{s.center.y} nohead lt 1\n"
        # str += "plot '-' with lines\n"
        # str += " 0 0 0 0\n"
        # str += "e\n"
        # str += "pause 0.005000\n"
        str
      end
      
      def save_gnuplot
        f = File.new($options.gnuplot_file,'w')
        f.write(to_gnuplot)
        f.close
        puts "Finished!"
        $stdout.flush
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
      
      protected
      
      def search(init, fringe, limit = 0)
        limited = false
        closed = Set.new
        fringe = fringe.insert(init)
        loop do
          # puts closed.size
          # puts
          if fringe.empty?
            puts "Done search: #{limit}"
            return (limited ? :limited : false)
          end
          node = fringe.remove
          log(node)
          if node.goal?
            puts "Done search: found"
            @n = node
            return node
          end
          if !closed.include?(node)
            closed.add(node)
            size = node.predecessors.size
            if size < limit
              node.succ.each do |n|
                n2 = n.clone
                n2.predecessors = ( node.predecessors.clone ) << node
                fringe.insert(n2)
              end
            else
              limited = true
            end
            # fringe.insert_all(node.succ)
          end
        end
      end
    end
    
    class DepthFirstSearch < UninformedSearch
      def start
        init = @hq.map.chunk_at_point(@tank.x, @tank.y)
        fringe = Collection::Stack.new
        search(init, fringe)
        save_gnuplot
      end
    end

    class DepthLimitedSearch < UninformedSearch
      def start
        init = @hq.map.chunk_at_point(@tank.x, @tank.y)
        iter_search(init)
        save_gnuplot
      end
      
      def iter_search(init)
        i = 1
        while (search([init], i)) == :limited
          puts "Iter depth: #{i}"
          i += 1
        end
      end

      def search(list, limit)
        (return :limited) if list.size > limit
        me = list.first
        return me if me.goal?
        puts "I am chunk #{me.x}, #{me.y}"
        log(me)
        result = false
        me.succ.each do |s|
          unless list.include?(s)
            puts ("  " * (list.size - 1)) + "successor #{s.x}, #{s.y}"
            s.predecessors = list.clone
            result = search([s] + list, limit)
            # p result.class
            # If it's a goal node, return right away
            return (@n = result) if result.is_a?(Chunk)
          end
        end
        # The last result will either be 'false' or :limited, and we should return it in either case
        return result
      end
      
    end

    class BreadthFirstSearch < UninformedSearch
      def start
        init = @hq.map.chunk_at_point(@tank.x, @tank.y)
        fringe = Collection::Queue.new
        search(init, fringe)
        save_gnuplot
      end
    end

    class InformedSearch < Search
      def start
        init = @hq.map.chunk_at_point(@tank.x, @tank.y)
        fringe = Collection::PriorityQueue.new
        @n = search(init, fringe)
        save_gnuplot
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

