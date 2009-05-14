bzrequire 'lib/agent/basic'
bzrequire 'lib/algorithms/heap'
bzrequire 'lib/algorithms/priority_queue'
require 'set'

class Collection
  def initialize(elems = [])
    @data = elems
  end
  def insert_all(elems)
    elems.each{ |e| insert(e) }
  end
  def empty?
    @data.empty?
  end
  def each(&block)
    @data.each(&block)
  end
end

class Stack < Collection
  def insert(e)
    @data.push(e)
  end
  def remove
    @data.pop
  end
end

#class Queue < Collection
#  def insert(e)
#    @data << e
#  end
#  def remove
#    @data.shift
#  end
#end

class PriorityQueue < Collection
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

module BraveZealot
  module Agent
    class Search < Basic
      def start
        init = @hq.map.chunk_at_point(@tank.x, @tank.y)
        fringe = Stack.new
        search(init, fringe)
      end
      
      protected
      
      def search(init, fringe)
        closed = Set.new
        fringe = fringe.insert(init)
        loop do
          return false if fringe.empty?
          node = fringe.remove
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

    class InformedSearch < Basic
      def start
        init = @hq.map.chunk_at_point(@tank.x, @tank.y)
        fringe = PriorityQueue.new
        n = search(init, fringe)
        
        f = File.new('search.gpi','w')
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
              n.g = node.g + (node.center.vector_to(n.center).length)
              n.predecessors = ( node.predecessors.clone ) << node
              fringe.insert(n)
            end
          end
        end
      end
      def log(n)
        #puts "Looking at node [#{n.x},#{n.y}] -> (#{n.g} + #{n.h} = #{n.cost})";
        @log ||= []
        @log << n
      end

      def get_log
        @log ||= []
      end

      def to_gnuplot
        str = @hq.map.to_gnuplot
        last = nil
        #arr = get_log.each do |n|
        #  if !last.nil?  then
        #    str += "set arrow from #{last.center.x}, #{last.center.y} to #{n.center.x}, #{n.center.y} nohead lt 5\n"
        #    str += "plot '-' with lines\n"
        #    str += " 0 0 0 0\n"
        #    str += "e\n"
        #    str += "pause 0.005000\n"
        #  end
        #  last = n
        #end
        s = get_log.last
        last = nil
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
        str
      end
    end
  end
end

