module DEVS
  module SequentialParallel
    module SimulatorImpl
      def init(time)
        @time_last = @model.time = time
        @time_next = @time_last + @model.time_advance
        debug "\t#{model} initialization (time_last: #{@time_last}, time_next: #{@time_next})" if DEVS.logger && DEVS.logger.debug?
        @time_next
      end

      def collect(time)
        raise BadSynchronisationError, "time: #{time} should match time_next: #{@time_next}" if time != @time_next
        @model.fetch_output!
      end

      def remainder(time, bag)
        synced = @time_last <= time && time <= @time_next

        if time == @time_next
          if bag.empty?
            debug "\tinternal transition: #{@model}" if DEVS.logger && DEVS.logger.debug?
            @transition_count[:internal] += 1
            @model.internal_transition
          else
            debug "\tconfluent transition: #{@model}" if DEVS.logger && DEVS.logger.debug?
            @transition_count[:confluent] += 1
            @model.confluent_transition(bag)
          end
        elsif synced && !bag.empty?
          debug "\texternal transition: #{@model}" if DEVS.logger && DEVS.logger.debug?
          @transition_count[:external] += 1
          @model.elapsed = time - @time_last
          @model.external_transition(bag)
        elsif !synced
          raise BadSynchronisationError, "time: #{time} should be between time_last: #{@time_last} and time_next: #{@time_next}"
        end

        @time_last = @model.time = time
        @time_next = @time_last + @model.time_advance
        debug "\t\ttime_last: #{@time_last} | time_next: #{@time_next}" if DEVS.logger && DEVS.logger.debug?
        @time_next
      end
    end
  end
end
