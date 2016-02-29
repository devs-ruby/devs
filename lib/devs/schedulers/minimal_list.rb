module DEVS
  class MinimalList

    def initialize(elements = nil)
      @min = nil
      if elements
        @ary = elements.dup
        reschedule!
      else
        @ary = []
      end
    end

    def prefer_mass_reschedule?
      true
    end

    def clear
      @ary.clear
      @min = nil
    end

    def <<(processor)
      @ary << processor
      @min = processor if !@min || processor.time_next < @min.time_next
    end
    alias_method :push, :<<
    alias_method :enqueue, :<<

    def delete(processor)
      index = @ary.index(processor)
      elmt = nil
      unless index.nil?
        elmt = @ary.delete_at(index)
        reschedule! if processor == @min
      end
      elmt
    end

    def peek
      reschedule! if !@min && @ary.size > 0
      @min
    end

    def pop
      return nil if @ary.size == 0
      reschedule! unless @min
      @ary.delete(@min)
      tmp = @min
      @min = nil
      tmp
    end
    alias_method :dequeue, :pop

    def peek_simultaneous
      a = []
      if @ary.size > 0
        time = self.peek.time_next
        i = 0
        while i < @ary.size
          a << @ary[i] if @ary[i].time_next == time
          i += 1
        end
      end
      a
    end
    alias_method :read_simultaneous, :peek_simultaneous

    def pop_simultaneous
      a = []
      if @ary.size > 0
        time = self.peek.time_next
        i = 0
        while i < @ary.size
          if @ary[i].time_next == time
            a << @ary.delete_at(i)
          else
            i += 1
          end
        end
        @min = nil
      end
      a
    end
    alias_method :dequeue_simultaneous, :pop_simultaneous

    def reschedule!
      @min = @ary.min { |a,b| a.time_next <=> b.time_next }
    end
  end
end
