module DEVS
  class MinimalListScheduler
    def initialize(elements = nil)
      @ary = elements || []
      @min = DEVS::INFINITY
      reschedule!
    end

    def schedule(processor)
      @ary << processor
      @min = processor.time_next if processor.time_next < @min
    end

    def unschedule(processor)
      index = @ary.index(processor)
      unless index.nil?
        @ary.delete_at(index)
        reschedule! if processor.time_next == @min
      end
    end

    def reschedule!
      min = DEVS::INFINITY
      i = 0
      while min > 0 || i < @ary.size
        p = @ary[i]
        min = p.time_next if p.time_next < min
        i += 1
      end
      @min = min
    end

    def read
      @min
    end

    def read_imminent(time)
      a = []
      i = 0
      while i < @ary.size
        p = @ary[i]
        a.push(p) if p.time_next == time
        i += 1
      end
      a
    end

    def imminent(time)
      a = []
      i = 0
      while i < @ary.size
        p = @ary[i]
        a.push(@ary.delete_at(i)) if p.time_next == time
        i += 1
      end
      a
    end
  end
end
