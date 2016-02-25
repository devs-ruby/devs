module DEVS
  # Multilist-based priority queue structure which achieve O(1) performance,
  # especially designed for managing the pending event set in discrete event
  # simulation. Its name, <i>LadderQueue</i>, arises from the semblance of the
  # structure to a ladder with rungs.
  #
  # Basically, the structure consists of three tiers: a sorted list called
  # <i>Bottom</i>; the middle layer, called <i>Ladder</i>, consisting of several
  # rungs of buckets where each bucket may contain an unsorted list; and a simple
  # unsorted list called <i>Top</i>.
  class LadderQueue
    include Logging

    # This class represent a general error for the {LadderQueue}.
    class LadderQueueError < StandardError; end

    # This class represent an error raised if the number of {Rung}s in
    # <i>Ladder</i> is equal to {#max_rungs} when an attempt to add a new rung
    # is made.
    class RungOverflowError < LadderQueueError; end

    # This class represent an error raised when an attempt to reset an active
    # {Rung} is made.
    class RungInUseError < LadderQueueError; end

    # This class represent a rung used in the <i>Ladder</i> tier of a
    # {LadderQueue}.
    #
    # Consist of buckets where each bucket may contain an unsorted list.
    class Rung
      attr_reader :current_bucket_index, :start_timestamp,
                  :total_event_count, :bucket_count, :bucket_width,
                  :current_timestamp

      # @!attribute [r] start_timestamp
      #   Starting timestamp threshold of the first bucket. Used for calculating
      #   the bucket-index when inserting an event.

      # @!attribute [r] current_timestamp
      #   Starting timestamp threshold of the first valid bucket which subsequent
      #   dequeue operations will start. Minimum timestamp threshold of events
      #   which can be enqueued.

      # @!attribute [r] bucket_count
      #   This attribute returns the number of buckets in <i>self</i>.
      #   @return [Fixnum] Returns the number of buckets in <i>self</i>

      def initialize
        @buckets = nil

        @start_timestamp = 0
        @current_bucket_index = 0
        @bucket_width = 0
        @total_event_count = 0
      end

      def inspect
        "<#{self.class}: start_timestamp=#{@start_timestamp}, current_timestamp=#{current_timestamp}>, current_bucket_index=#{@current_bucket_index}, bucket_width=#{@bucket_width}, buckets=#{@buckets ? @buckets.size : 'nil'}, events=#{@total_event_count}>"
      end

      def current_bucket_count
        @buckets[@current_bucket_index].size
      end

      def bucket_count
        @buckets.size
      end

      def current_timestamp
        @start_timestamp + @current_bucket_index * @bucket_width
      end

      def next_bucket!
        i = @current_bucket_index
        while i < @buckets.size && @buckets[i].size == 0
          i+=1
        end
        @current_bucket_index = i > @buckets.size-1 ? @buckets.size-1 : i
      end

      def rewind!
        @current_bucket_index = 0
        self
      end

      def clear
        @start_timestamp = 0
        @current_bucket_index = 0
        @bucket_width = 0
        @total_event_count = 0
      end

      def [](index)
        @buckets[index]
      end

      def clear_current_bucket
        bucket = @buckets[@current_bucket_index]
        @total_event_count -= bucket.size
        @buckets[@current_bucket_index] = []
        bucket
      end

      def reset(bucket_width, num_events, timestamp)
        raise RungInUseError if @total_event_count > 0

        bucket_count = num_events + 1
        @bucket_width = bucket_width
        if @buckets.nil?
          @buckets = Array.new(bucket_count) { [] }
        else
          @buckets = @buckets[0, bucket_count] if @buckets.size > bucket_count
          i = 0
          while i < @buckets.size
            @buckets[i].clear
            i += 1
          end
          if @buckets.size < bucket_count
            while i < bucket_count
              @buckets << []
              i += 1
            end
          end
        end

        @total_event_count = 0
        @current_bucket_index = 0
        @start_timestamp = timestamp
      end

      def delete(obj)
        item = nil
        bucket = bucket_for(obj)
        index = bucket.index(obj)
        if index
          item = bucket.delete_at(index)
          @total_event_count -= 1
        end
        item
      end

      def <<(obj)
        bucket_for(obj) << obj
        @total_event_count += 1
      end
      alias_method :push, :<<

      def concat(list)
        i = 0
        while i < list.size
          self << list[i]
          i+=1
        end
      end

      private
      def bucket_for(obj)
        tn = obj.time_next
        index = ((tn - @start_timestamp) / @bucket_width).round
        if index < 0 || index > @buckets.size-1
          raise RangeError, "bucket index #{index} out of range for event #{tn}"
        end
        @buckets[index]
      end
    end

    # The default number of events in a bucket or bottom to not exceed. If so,
    # a spawning action would be initiated.
    DEFAULT_THRESHOLD = 50

    # The default max number of rungs in the middle layer (Ladder)
    DEFAULT_MAX_RUNGS = 8

    attr_reader :size, :top_size, :bottom_size, :active_rungs, :size,
                :threshold, :max_rungs, :top_max, :top_min, :top_start, :epoch

    # @!attribute [r] top_size
    #   This attribute returns the number of events in <i>Top</i>
    #   @return [Fixnum] Returns the number of events in <i>Top</i>

    # @!attribute [r] bottom_size
    #   This attribute returns the number of events in <i>Bottom</i>
    #   @return [Fixnum] Returns the number of events in <i>Bottom</i>

    # @!attribute [r] active_rungs
    #   This attribute returns the number of rungs currently in active use
    #   @return [Fixnum] Returns the number of active rungs

    # @!attribute [r] size
    #   This attribute returns the total number of events in <i>self</i>.
    #   @return [Fixnum] Returns the total number of events

    # @!attribute [r] threshold
    #   This attribute returns the number of events in a bucket or bottom to not
    #   exceed. If so, a spawning action would be initiated.
    #   @return [Fixnum] Returns the number of events threshold

    # @!attribute [r] top_min
    #   This attribute returns the minimum timestamp of all events in <i>Top</i>.
    #   Its value is updated as events are enqueued into <i>Top</i>.
    #   @return [Fixnum] Returns the minimum timestamp in <i>Top</i>

    # @!attribute [r] top_max
    #   This attribute returns the maximum timestamp of all events in <i>Top</i>.
    #   Its value is updated as events are enqueued into <i>Top</i>.
    #   @return [Fixnum] Returns the maximum timestamp in <i>Top</i>

    # @!attribute [r] top_start
    #   This attribute returns the minimum timestamp threshold of events which
    #   must be enqueued in <i>Top</i>
    #   @return [Fixnum] Returns the minimum timestamp threshold of events which
    #     must be enqueued in <i>Top</i>

    # @!attribute [r] max_rungs
    #   This attribute returns the maximum number of rungs that can be spawned.
    #   @return [Fixnum] Returns the maximum number of rungs in <i>self</i>

    # @!attribute [r] epoch
    #   This attribute returns the epoch at which <i>self</i> operates. The
    #   first epoch is marked by the creation of the <i>Ladder</i> and
    #   <i>Bottom</i> structure. Epochs ends when the <i>Ladder</i> and
    #   <i>Bottom</i> structure are empty.
    #   @return [Fixnum] Returns the epoch at which <i>self</i> operates.

    def initialize(elements = nil, threshold = DEFAULT_THRESHOLD, max_rungs = DEFAULT_MAX_RUNGS)
      @threshold = threshold
      @max_rungs = max_rungs
      @active_rungs = 0
      @max_active_rungs = 0
      @size = 0
      @epoch = 0

      # Unsorted list
      @top = []
      # The middle layer (ladder) consisting of several rungs of buckets where
      # each bucket may contain an unsorted list
      @rungs = Array.new(max_rungs) { Rung.new }
      # Sorted list
      @bottom = []

      # Maximum timestamp of all events in top. Its value is updated as events are
      # enqueued into top
      @top_max = nil
      # Minimum timestamp of all events in top. Its value is updated as events are
      # enqueued into top
      @top_min = nil
      # Minimum timestamp threshold of events which must be enqueued in top
      @top_start = 0

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
      "<#{self.class}: epoch=#{@epoch}, size=#{@size}, top=#{@top.size}, bottom=#{@bottom.size}, active_rungs=#{@active_rungs}, threshold=#{@threshold}, max_rungs=#{@max_rungs}, top_start=#{@top_start || 'nil'}, top_min=#{@top_min || 'nil'}, top_max=#{@top_max || 'nil'}, rungs=#{@rungs[0, @active_rungs]}>"
    end

    def top_size
      @top.size
    end

    def bottom_size
      @bottom.size
    end

    def ladder_size
      @size - (@top.size + @bottom.size)
    end

    def empty?
      @size == 0
    end

    def <<(obj)
      timestamp = obj.time_next

      # check wether event should be in top
      if timestamp > @top_start
        @top << obj
        @top_min = timestamp if @top_min.nil? || timestamp < @top_min
        @top_max = timestamp if @top_max.nil? || timestamp > @top_max
      else
        # check whether event should be in ladder or bottom
        x = 0
        x += 1 while timestamp < @rungs[x].current_timestamp && x < @active_rungs

        # if timestamp is lower than the maximum timestamp from bottom, this
        # this event should be in bottom.
        should_be_in_bottom = @bottom.size > 0 && timestamp <= @bottom.first.time_next

        if x < @active_rungs && !should_be_in_bottom
          # add to appropriate rung
          @rungs[x] << obj
        else
          if @bottom.size + 1 > @threshold
            # add new event to bottom
            push_bottom(obj)

            if @active_rungs > 0
              # rewind current rung to it's start and transfer bottom into it
              #info("LadderQueue rewind current rung to it's start and transfer bottom into it")

              rung = @rungs[@active_rungs-1]
              if rung.start_timestamp > @bottom.last.time_next
                i = @bottom.size-1
                i -= 1 while rung.start_timestamp > @bottom[i].time_next
                rung.rewind!.concat(@bottom.slice!(0, i))
              else
                rung.rewind!.concat(@bottom)
                @bottom.clear
              end
            else
              max = @bottom.first.time_next
              min = @bottom.last.time_next

              # create first rung and transfer bottom into it only if timestamps
              # are not identical.
              if max - min > 0
                @rungs.first.reset((@bottom.first.time_next.to_f - @bottom.last.time_next.to_f) / @bottom.size, @bottom.size, @bottom.last.time_next)
                @active_rungs = 1
                @epoch += 1
                #info("LadderQueue NEW EPOCH, spawn first rung (from #insert): #{@rungs.first.inspect}") if DEVS.logger
                @rungs.first.concat(@bottom)
                @bottom.clear
              end
            end
          else
            # sort new event into bottom
            push_bottom(obj)
          end
        end
      end
      @size += 1
      self
    end
    alias_method :push, :<<
    alias_method :enqueue, :<<

    def delete(obj)
      timestamp = obj.time_next
      item = nil

      if @size > 0
        new_epoch if @active_rungs == 0

        if timestamp > @top_start
          index = @top.index(obj)
          item = @top.delete_at(index) unless index.nil?
        else
          x = 0
          x += 1 while timestamp < @rungs[x].current_timestamp && x < @active_rungs

          item = @rungs[x].delete(obj) if x < @active_rungs

          unless item
            index = @bottom.index(obj)
            item = @bottom.delete_at(index) unless index == nil
          end
        end

        @size -= 1 if item
      end

      #warn("LadderQueue failed to delete #{timestamp}: #{obj.inspect}(model: #{obj.model.name}) | top_start: #{@top_start}") if DEVS.logger && item == nil
      item
    end

    def peek
      prepare! if @bottom.empty?
      @bottom.last
    end

    def pop
      prepare! if @bottom.size == 0
      return nil if @bottom.size == 0
      # return next event from bottom
      @size -= 1
      @bottom.pop
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

    def clear
      @top.clear
      @bottom.clear
      @rungs.each { |r| r.clear }

      @active_rungs = 0
      @size = 0
      @epoch = 0
      @top_max = nil
      @top_min = nil
      @top_start = 0
    end

    private
    def prepare!
      while @bottom.empty?
        if @active_rungs > 0
          rung = @rungs[@active_rungs-1]

          # transfer from rung to bottom if not empty
          unless rung.total_event_count == 0
            rung = recurse_rungs
            events = rung.clear_current_bucket

            size = events.size
            # sort bucket into bottom
            i = 0
            while i < size
              push_bottom(events[i])
              i += 1
            end
          end

          # invalidate rung if empty
          while @active_rungs > 0 && rung.total_event_count == 0
            rung.clear
            @active_rungs -= 1
            #info("LadderQueue invalidated rung from prepare!. Active rungs: #{@active_rungs}") if DEVS.logger
            rung = @rungs[@active_rungs - 1]
          end
        else
          break if @top.size == 0 # no more events in top, nothing to do
          new_epoch
        end
      end

      self
    end

    def new_epoch
      # no more events in ladder & bottom, new epoch

      if @top_max - @top_min == 0
        # all timestamps are identical, no sort required
        # transfer directly events from top into bottom (shortcut)
        tmp = @bottom
        @bottom = @top
        @top = tmp
        #info("LadderQueue NEW EPOCH, transfer directly from TOP to BOTTOM (#{@bottom.size} events)") if DEVS.logger
      else
        rung = @rungs.first
        rung.reset((@top_max.to_f - @top_min.to_f) / @top.size, @top.size, @top_min)
        #info("LadderQueue NEW EPOCH, spawn first rung: #{rung.inspect}") if DEVS.logger
        @active_rungs = 1
        rung.concat(@top)
        @top.clear
      end

      @epoch += 1
      @top_start = @top_max
      @top_max = @top_min = nil
    end

    def recurse_rungs
      lowest = @rungs[@active_rungs - 1]
      found = false
      # until an acceptable bucket is found
      until found
        # find next non-empty bucket
        lowest.next_bucket!

        # create a new rung if bucket gets too big
        if lowest.current_bucket_count > @threshold
          if @active_rungs == @max_rungs
            #warn("LadderQueue reached its max number of rungs (#{@max_rungs})") if DEVS.logger
            # if ladder reached its maximum number of rungs, events in the
            # current dequeue bucket, associated with the last rung, are
            # sorted to create Bottom even though the number of events may
            # exceed threshold
            found = true
          else
            events = lowest.clear_current_bucket
            rung = add_rung(events.size)
            rung.concat(events)
            lowest = rung
            #info("LadderQueue bucket too big. Spawning new rung: #{rung.inspect}") if DEVS.logger
          end
        else
          found = true
        end
      end

      lowest
    end

    def push_bottom(obj)
      if @bottom.empty?
        @bottom << obj
      else
        index = @bottom.size - 1
        tn = obj.time_next
        index -= 1 while tn > @bottom[index].time_next && index >= 0
        @bottom.insert(index + 1, obj)
      end
    end

    def add_rung(n)
      raise RungOverflowError if @active_rungs == @max_rungs
      current_rung = @rungs[@active_rungs-1]
      new_rung = @rungs[@active_rungs]
      width = current_rung.bucket_width / n

      # set bucket width to current rung's bucket width / thres
      # set start and current of the new rung to current marking of the current bucket
      new_rung.reset(width, n, current_rung.current_timestamp)
      @active_rungs += 1
      @max_active_rungs = @active_rungs if @active_rungs > @max_active_rungs
      new_rung
    end
  end
end
