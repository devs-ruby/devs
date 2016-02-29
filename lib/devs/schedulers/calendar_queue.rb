module DEVS

  # A fast O(1) priority queue implementation
  class CalendarQueue
    include Logging
    attr_reader :size

    # @!attribute [r] size
    #   This attribute returns the total number of events in <i>self</i>.
    #   @return [Fixnum] Returns the total number of events

    def initialize(elements = nil, start_priority=0.0, bucket_count=2, bucket_width=1.0)
      @size = 0
      @resize_enabled = true

      # the bucket index from which the last event was dequeued
      @last_bucket = 0
      # the priority at the top of that bucket (highest priority that could go
      # into the bucket)
      @bucket_top = 0
      # the priority of the last event dequeued
      @last_priority = 0

      local_init(bucket_count, bucket_width, start_priority)

      if elements
        i = 0
        while i < elements.size
          self << elements[i]
          i+=1
        end
      end
    end

    def prefer_mass_reschedule?
      false
    end

    def inspect
      "<#{self.class}: size=#{@size}, bucket_width=#{@width}, last_priority=#{@last_priority}, last_bucket=#{@last_bucket}, bucket_top=#{@bucket_top}, shrink_threshold=#{@shrink_threshold}, expand_threshold=#{@expand_threshold}>"
    end

    def empty?
      @size == 0
    end

    def clear
      @size = 0
      @resize_enabled = true
      @last_bucket = 0
      @bucket_top = 0
      @last_priority = 0
      local_init(2, 1.0, 0.0)
    end

    def <<(obj)
      tn = obj.time_next
      i = tn / @width       # virtual bucket
      i = i % @buckets.size # actual bucket

      bucket = @buckets[i]
      if bucket.empty? || bucket.last.time_next > tn
        bucket << obj
      else
        j = bucket.size - 1
        j -= 1 while tn > bucket[j].time_next && j >= 0
        bucket.insert(j + 1, obj)
      end

      # check last priority and update last bucket accordingly
        # b = @last_bucket
        # cur_bucket = @buckets[b]
        # btop = @bucket_top
        # j = 0
        # while j < @buckets.size-1 && @buckets[b].empty?
        #   j+=1
        #   b = (b+1) % @buckets.size
        #   btop += @width
        # end
        # cur_bucket = @buckets[b]
        # if cur_bucket.size > 0 && tn < cur_bucket.last.time_next && cur_bucket.last.time_next < btop
        #   #info("CQ push: ts #{tn} < cur_bucket next ts #{cur_bucket.last.time_next} (btop at #{btop}). update bucket from #{@last_bucket} to #{i}") if DEVS.logger
        #   @last_bucket = i.to_i
        #   @last_priority = bucket.last.time_next
        #   @bucket_top = (((@last_priority / @width) + 1).to_i * @width + (0.5 * @width)).to_f
        # end

      @size += 1

      #info("CQ added #{tn} at bucket #{i.to_i}: #{obj.inspect}(model: #{obj.model.name})") if DEVS.logger && @resize_enabled

      # double the calendar size if needed
      #info("CQ double calendar size. #{@buckets.size} to #{@buckets.size * 2} buckets. threshold=#{@expand_threshold}") if @size > @expand_threshold && DEVS.logger && @resize_enabled
      resize(2 * @buckets.size) if @size > @expand_threshold

      self
    end
    alias_method :push, :<<
    alias_method :enqueue, :<<

    def delete(obj)
      tn = obj.time_next
      i = tn / @width       # virtual bucket
      i = i % @buckets.size # actual bucket

      bucket = @buckets[i]
      item = nil
      index = bucket.index(obj)
      if index
        item = bucket.delete_at(index)
        @size -= 1
      end

      # halve calendar size if needed
      #info("CQ halve calendar size. #{@buckets.size} to #{@buckets.size / 2} buckets. threshold=#{@shrink_threshold}") if @size < @shrink_threshold && DEVS.logger
      resize(@buckets.size / 2) if @size < @shrink_threshold
      #info("CQ deleted #{tn} from bucket #{i.to_i}: #{obj.inspect}(model: #{obj.model.name})") if DEVS.logger && item

      item
    end

    def peek
      return nil if @size == 0

      last_bucket = @last_bucket
      last_priority = @last_priority
      bucket_top = @bucket_top

      while true
        i = last_bucket
        while i < @buckets.size
          bucket = @buckets[i]

          if bucket.size > 0 && bucket.last.time_next < bucket_top
            # found item to dequeue
            item = bucket.last
            last_bucket = i
            last_priority = item.time_next

            return item
          else
            # prepare to check next bucket or else go to a direct search
            i += 1
            i = 0 if i == @buckets.size
            bucket_top += @width

            break if i == last_bucket # go to direct search
          end
        end

        # directly search for minimum priority event
        lowest = Float::INFINITY
        i = tmp = 0
        while i < @buckets.size
          bucket = @buckets[i]
          if bucket.size > 0 && bucket.last.time_next < lowest
            lowest = bucket.last.time_next
            tmp = i
          end
          i += 1
        end
        last_bucket = tmp
        last_priority = lowest
        bucket_top = (((lowest / @width) + 1).to_i * @width + (0.5 * @width)).to_f

        # resume search at min bucket
      end
    end

    def pop
      return nil if @size == 0

      i = @last_bucket
      while i < @buckets.size
        bucket = @buckets[i]

        if bucket.size > 0 && bucket.last.time_next < @bucket_top
          # found item to dequeue
          item = bucket.pop
          @last_bucket = i
          @last_priority = item.time_next
          @size -= 1

          # halve calendar size if needed
          #info("CQ halve calendar size. #{@buckets.size} to #{@buckets.size / 2} buckets. threshold=#{@shrink_threshold}") if @size < @shrink_threshold && DEVS.logger && @resize_enabled
          resize(@buckets.size / 2) if @size < @shrink_threshold

          #info("CQ pop #{item.time_next}: #{item.inspect}(model: #{item.model.name})") if DEVS.logger && @resize_enabled

          return item
        else
          # prepare to check next bucket or else go to a direct search
          i += 1
          i = 0 if i == @buckets.size
          @bucket_top += @width

          break if i == @last_bucket # go to direct search
        end
      end

      # directly search for minimum priority event
      lowest = Float::INFINITY
      i = tmp = 0
      while i < @buckets.size
        bucket = @buckets[i]
        if bucket.size > 0 && bucket.last.time_next < lowest
          lowest = bucket.last.time_next
          tmp = i
        end
        i += 1
      end
      @last_bucket = tmp
      @last_priority = lowest
      @bucket_top = (((lowest / @width) + 1).to_i * @width + (0.5 * @width)).to_f
      pop # resume search at min bucket
    end
    alias_method :dequeue, :pop

    def pop_simultaneous
      a = []
      if @size > 0
        time = self.peek.time_next
        a << self.pop while @size > 0 && self.peek.time_next == time
      end
      a
    end
    alias_method :dequeue_simultaneous, :pop_simultaneous

    private
    # Initializes a bucket array within
    def local_init(bucket_count, bucket_width, start_priority)
      @width = bucket_width
      old = @buckets
      @buckets = if @cached_buckets == nil
        Array.new(bucket_count) { [] }
      else
        n = @cached_buckets.size
        if bucket_count < n
          # shrink the array
          @cached_buckets.slice!(bucket_count, n)
        else
          # expand the array
          @cached_buckets.fill(n, bucket_count - n) { [] }
        end
        @cached_buckets
      end
      @cached_buckets = old

      @last_priority = start_priority
      i = start_priority / bucket_width # virtual bucket
      @last_bucket = (i % bucket_count).to_i
      @bucket_top = (i+1) * bucket_width + 0.5 * bucket_width

      # set up queue size change thresholds
      @shrink_threshold = bucket_count / 2 - 2
      @expand_threshold = 2 * bucket_count
    end

    # Resize buckets to new_size.
    def resize(new_size)
      return unless @resize_enabled

      bucket_width = new_width # find new bucket width
      local_init(new_size, bucket_width, @last_priority)

      i = 0
      while i < @cached_buckets.size
        bucket = @cached_buckets[i]
        @size -= bucket.size
        while obj = bucket.pop
          self << obj
        end
        i += 1
      end
    end

    # Calculates the width to use for buckets
    def new_width
      # decides how many queue elements to sample
      return 1.0 if @size < 2
      n = if @size <= 5
        @size
      else
        5 + (@size / 10).to_i
      end
      n = 25 if n > 25

      # record variables
      tmp_last_bucket = @last_bucket
      tmp_last_priority = @last_priority
      tmp_bucket_top = @bucket_top

      # dequeue n events from the queue and record their priorities with
      # resize_enabled set to false.
      @resize_enabled = false
      tmp = Array.new(n)
      average = 0.0
      i = 0
      while i < n
        # dequeue events to get a test sample
        tmp[i] = self.pop
        # and sum up the differences in time
        average += tmp[i].time_next - tmp[i-1].time_next if i > 0
        i += 1
      end

      # calculate average separation of sampled events
      average = average / (n-1).to_f

      # put the first sample back onto the queue
      self << tmp[0]

      # recalculate average using only separations smaller than twice the
      # original average
      new_average = 0.0
      j = 0
      i = 1
      while i < n
        sub = tmp[i].time_next - tmp[i-1].time_next
        if sub < average * 2.0
          new_average += sub
          j += 1
        end
        # put the remaining samples back onto the queue
        self << tmp[i]
        i += 1
      end
      new_average = new_average / j.to_f

      # restore variables
      @resize_enabled = true
      @last_bucket = tmp_last_bucket
      @last_priority = tmp_last_priority
      @bucket_top = tmp_bucket_top

      # this is the new width
      if new_average > 0.0
        new_average * 3.0
      elsif average > 0.0
        average * 2.0
      else
        1.0
      end
    end
  end
end
