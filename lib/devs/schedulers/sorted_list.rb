module DEVS
  class SortedList
    def initialize(elements = nil)
      if elements
        @ary = elements.dup
        reschedule!
      end
    end

    def prefer_mass_reschedule?
      true
    end

    def size
      @ary.size
    end

    def empty?
      @ary.empty?
    end

    def peek
      return nil if @ary.empty?
      @ary.last
    end

    def <<(obj)
      @ary << obj
    end
    alias_method :push, :<<
    alias_method :enqueue, :<<

    def pop
      @ary.pop
    end
    alias_method :dequeue, :pop

    def pop_simultaneous
      a = []
      if @ary.size > 0
        time = @ary.last.time_next
        a << @ary.pop while @ary.size > 0 && @ary.last.time_next == time
      end
      a
    end
    alias_method :dequeue_simultaneous, :pop_simultaneous

    def peek_simultaneous
      a = []
      if @ary.size > 0
        time = @ary.last.time_next
        i = @ary.size - 1
        while i >= 0
          if @ary[i].time_next == time
            a << @ary[i]
            i -= 1
          else
            break
          end
        end
      end
      a
    end
    alias_method :read_simultaneous, :peek_simultaneous

    def delete(obj)
      i = @ary.size - 1
      elmt = nil
      while i >= 0
        if @ary[i] == processor
          elmt = @ary.delete_at(i)
          break
        end
        i -= 1
      end
      elmt
    end

    def reschedule!
      @ary.sort! { |a,b| b.time_next <=> a.time_next }
      self
    end
  end
end
