module Collection
  class Base
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
end