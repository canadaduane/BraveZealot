bzrequire 'lib/collection/base'

module Collection
  class Stack < Base
    def insert(e)
      @data.push(e)
      self
    end
    def remove
      @data.pop
    end
  end
end
