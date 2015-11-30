module DEVS
  module Classic
    module SimulatorImpl
      # Handles init (i) messages
      #
      # @param time
      def init(time)
        @time_last = model.time = time
        @time_next = @time_last + model.time_advance
        debug "\t#{model} initialization (time_last: #{@time_last}, time_next: #{@time_next})" if DEVS.logger && DEVS.logger.debug?
        @time_next
      end

      # Process internal (*) messages
      #
      # @param time
      # @raise [BadSynchronisationError] if the time is not equal to
      #   {Coordinator#time_next}
      def internal_message(time)
        if time != @time_next
          raise BadSynchronisationError, "time: #{time} should match time_next: #{@time_next}"
        end

        output_bag = model.fetch_output!
        debug "\tinternal transition: #{model}" if DEVS.logger && DEVS.logger.debug?
        @transition_count[:internal] += 1
        model.internal_transition

        @time_last = model.time = time
        @time_next = time + model.time_advance
        debug "\t\ttime_last: #{@time_last} | time_next: #{@time_next}" if DEVS.logger && DEVS.logger.debug?
        output_bag
      end

      # Handles input (x) messages
      #
      # @param time
      # @param payload [Object]
      # @param port [Port]
      # @raise [BadSynchronisationError] if the time isn't in a proper
      #   range, e.g isn't between {Coordinator#time_last} and
      #   {Coordinator#time_next}
      def handle_input(time, payload, port)
        if @time_last <= time && time <= @time_next
          @transition_count[:external] += 1
          model.elapsed = time - @time_last
          debug "\texternal transition: #{model}" if DEVS.logger && DEVS.logger.debug?
          model.external_transition({port => payload})
          @time_last = model.time = time
          @time_next = time + model.time_advance
          debug "\t\ttime_last: #{@time_last} | time_next: #{@time_next}" if DEVS.logger && DEVS.logger.debug?
        else
          raise BadSynchronisationError, "time: #{time} should be between time_last: #{@time_last} and time_next: #{@time_next}"
        end
      end
    end
  end
end
