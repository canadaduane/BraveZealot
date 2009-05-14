bzrequire 'lib/agent/basic'
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

class Queue < Collection
  def insert(e)
    @data << e
  end
  def remove
    @data.shift
  end
end

class PriorityQueue < Collection
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
  end
end

