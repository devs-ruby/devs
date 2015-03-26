module DEVS
  module Classic
    module CoordinatorImpl

      # Handles init (i) messages
      #
      # @param time
      def init(time)
        i = 0
        selected = []
        min = DEVS::INFINITY
        while i < @children.size
          child = @children[i]
          tn = child.init(time)
          selected.push(child) if tn < DEVS::INFINITY
          min = tn if tn < min
          i += 1
        end
        # @scheduler = if DEVS.scheduler == MinimalListScheduler || DEVS.scheduler == SortedListScheduler
        #   DEVS.scheduler.new(@children)
        # else
        @scheduler = DEVS.scheduler.new(selected)
        #end

        @time_last = max_time_last
        @time_next = min
      end

      # Handles internal (*) messages
      #
      # @param time
      # @raise [BadSynchronisationError] if the time is not equal to
      #   {Coordinator#time_next}
      def internal_message(time)
        if time != @time_next
          raise BadSynchronisationError,
                "time: #{time} should match time_next: #{@time_next}"
        end

        # imm = if DEVS.scheduler == MinimalListScheduler || DEVS.scheduler == SortedListScheduler
        #   read_imminent_children
        # else
        imm = @scheduler.dequeue_simultaneous
        #end

        child = if imm.size > 1
          children_models = imm.map(&:model)
          child_model = model.select(children_models)
          imm[children_models.index(child_model)]
        else
          imm.first
        end

        # if DEVS.scheduler == MinimalListScheduler || DEVS.scheduler == SortedListScheduler
        #   child.internal_message(time)
        #   @scheduler.reschedule!
        # else
        i = 0
        while i < imm.size
          c = imm[i]
          @scheduler.enqueue(c) unless c == child
          i += 1
        end
        child.internal_message(time)
        @scheduler.enqueue(child) if child.time_next < DEVS::INFINITY
        #end

        @time_last = time
        @time_next = min_time_next
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

          eic = @model.input_couplings(port)
          i = 0
          while i < eic.size
            coupling = eic[i]
            child = coupling.destination.processor
            # if DEVS.scheduler == MinimalListScheduler || DEVS.scheduler == SortedListScheduler
            #   child.handle_input(time, payload, coupling.destination_port)
            # else
            @scheduler.delete(child) if child.time_next < DEVS::INFINITY
            child.handle_input(time, payload, coupling.destination_port)
            @scheduler.enqueue(child) if child.time_next < DEVS::INFINITY
            #end
            #@scheduler.reschedule! if DEVS.scheduler == MinimalListScheduler || DEVS.scheduler == SortedListScheduler
            i += 1
          end

          @time_last = time
          @time_next = min_time_next
        else
          raise BadSynchronisationError, "time: #{time} should be between time_last: #{@time_last} and time_next: #{@time_next}"
        end
      end

      # Handles output (y) messages
      #
      # @param time
      # @param payload [Object]
      # @param port [Port]
      def handle_output(time, payload, port)
        eoc = @model.output_couplings(port)
        i = 0
        while i < eoc.size
          coupling = eoc[i]
          parent.handle_output(time, payload, coupling.destination_port)
          i += 1
        end

        ic = @model.internal_couplings(port)
        i = 0
        while i < ic.size
          coupling = ic[i]
          child = coupling.destination.processor
          # if DEVS.scheduler == MinimalListScheduler || DEVS.scheduler == SortedListScheduler
          #   child.handle_input(time, payload, coupling.destination_port)
          # else
          @scheduler.delete(child) if child.time_next < DEVS::INFINITY
          child.handle_input(time, payload, coupling.destination_port)
          @scheduler.enqueue(child) if child.time_next < DEVS::INFINITY
          # end
          i += 1
        end
      end
    end
  end
end
