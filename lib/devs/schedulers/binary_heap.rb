module DEVS
  # Scheduler with array based heap.
  #
  # Each inserted elements is given a certain priority, based on the result of
  # the comparison. Also, retrieving an element will always return the one with
  # the highest priority. The internal queue is kept in the reverse order.
  #
  class BinaryHeap
    def initialize(elements = nil)
      @que = []
      replace(elements) if elements
    end

    def prefer_mass_reschedule?
      false
    end

    protected
    attr_reader :que

    public

    def size
      @que.size
    end

    def clear
      @que.clear
    end

    def empty?
      @que.size == 0
    end

    def enqueue(processor)
      @que << processor
      reheap(@que.size - 1)
      self
    end
    alias_method :push, :enqueue
    alias_method :<<, :enqueue

    def index(processor)
      idx = nil
      i = @que.size - 1
      while i >= 0
        if @que[i] == processor
          idx = i
          break
        end
        i -= 1
      end
      idx
    end
    private :index

    def delete(processor)
      tn = processor.time_next
      elmt = nil
      if @que.last.time_next - @que.first.time_next == 0
        i = @que.index(processor)
        elmt = @que.delete_at(i) unless i == nil
      else
        i = binary_index(@que, processor)
        while i >= 0 && @que[i].time_next == tn
          if @que[i].equal?(processor)
            elmt = @que.delete_at(i)
            break
          end
          i -= 1
        end
      end
      elmt
    end

    def peek
      @que.last
    end

    def pop
      @que.pop
    end
    alias_method :dequeue, :pop

    def pop_simultaneous
      a = []
      if @que.size > 0
        time = @que.last.time_next
        a << @que.pop while !@que.empty? && @que.last.time_next == time
      end
      a
    end
    alias_method :dequeue_simultaneous, :pop_simultaneous

    def to_a
      @que.dup
    end

    def reschedule!
      @que.sort! { |a,b| b.time_next <=> a.time_next }
      self
    end

    def concat(elements)
      if empty?
        if elements.kind_of?(BinaryHeap)
          initialize_copy(elements)
        else
          replace(elements)
        end
      else
        if elements.kind_of?(BinaryHeap)
          @que.concat(elements.que)
          reschedule!
        else
          @que.concat(elements.to_a)
          reschedule!
        end
      end
      return self
    end

    def replace(elements)
      if elements.kind_of?(BinaryHeap)
        initialize_copy(elements)
      else
        @que.replace(elements.to_a)
        reschedule!
      end
      self
    end

    def inspect
      "<#{self.class}: size=#{size}, top=#{top || "nil"}>"
    end

    def ==(other)
      size == other.size && to_a == other.to_a
    end

    private

    def initialize_copy(other)
      @que = other.que.dup
      reschedule!
    end

    def reheap(k)
      return self if size <= 1

      v = @que.delete_at(k)
      i = binary_index(@que, v)
      @que.insert(i, v)

      return self
    end

    def binary_index(que, target)
      upper = que.size - 1
      lower = 0

      while(upper >= lower) do
        idx  = lower + (upper - lower) / 2
        comp = que[idx].time_next <=> target.time_next

        if comp == 0
          return idx
        elsif comp > 0
          lower = idx + 1
        else
          upper = idx - 1
        end
      end
      lower
    end
  end
end
