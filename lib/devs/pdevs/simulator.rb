module DEVS
  module PDEVS
    class Simulator < DEVS::Simulator

      def initialize_processor(time)
        @transition_count.clear
        @model._initialize_state
        @time_last = @model.time = time
        @time_next = @time_last + @model.time_advance
        if @run_validations && @model.invalid?(:init)
          if DEVS.logger
            error "model #{@model.name} is invalid for init context: #{@model.errors.full_messages}"
          end
        end
        @model.changed
        @model.notify_observers(@model, :init)
        debug "\t#{model} initialization (time_last: #{@time_last}, time_next: #{@time_next})" if DEVS.logger && DEVS.logger.debug?
        @time_next
      end

      def collect(time)
        raise BadSynchronisationError, "time: #{time} should match time_next: #{@time_next}" if time != @time_next
        @model._fetch_output!
      end

      def remainder(time, bag)
        synced = @time_last <= time && time <= @time_next

        if time == @time_next
          if bag.empty?
            debug "\tinternal transition: #{@model}" if DEVS.logger && DEVS.logger.debug?
            @transition_count[:internal] += 1
            @model.internal_transition
            kind = :internal
          else
            debug "\tconfluent transition: #{@model}" if DEVS.logger && DEVS.logger.debug?
            @transition_count[:confluent] += 1
            @model.elapsed = 0
            @model.confluent_transition(bag)
            kind = :confluent
          end
        elsif synced && !bag.empty?
          debug "\texternal transition: #{@model}" if DEVS.logger && DEVS.logger.debug?
          @transition_count[:external] += 1
          @model.elapsed = time - @time_last
          @model.external_transition(bag)
          kind = :external
        elsif !synced
          raise BadSynchronisationError, "time: #{time} should be between time_last: #{@time_last} and time_next: #{@time_next}"
        end

        @time_last = @model.time = time
        @time_next = @time_last + @model.time_advance

        if @run_validations && @model.invalid?(kind)
          if DEVS.logger
            error "model #{@model.name} is invalid for #{kind} context: #{@model.errors.full_messages}"
          end
        end
        @model.changed
        # NOTE #notify_observers use splat arguments -> lot of array allocations
        @model.notify_observers(@model, kind)

        debug "\t\ttime_last: #{@time_last} | time_next: #{@time_next}" if DEVS.logger && DEVS.logger.debug?
        @time_next
      end
    end
  end
end
