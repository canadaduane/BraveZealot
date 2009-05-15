bzrequire 'lib/collection/base'

module Collection
  class Queue < Base
    def insert(e)
      @data << e
      self
    end
    def remove
      @data.shift
    end
  end
end
