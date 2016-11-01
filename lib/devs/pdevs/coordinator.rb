module DEVS
  module PDEVS
    class Coordinator < DEVS::Coordinator
      def initialize(model, scheduler:, namespace:, run_validations:)
        super(model, scheduler: scheduler, namespace: namespace, run_validations: run_validations)
        @influencees = Hash.new { |h,k| h[k] = Hash.new { |h2,k2| h2[k2] = [] }}
        @synchronize = {}
        @parent_bag = Hash.new { |h,k| h[k] = [] }
      end

      def initialize_processor(time)
        i = 0
        selected = []
        min = DEVS::INFINITY
        while i < @children.size
          child = @children[i]
          tn = child.initialize_processor(time)
          selected.push(child) if tn < DEVS::INFINITY
          min = tn if tn < min
          i += 1
        end

        @scheduler.clear
        list = @scheduler.prefer_mass_reschedule? ? @children : selected
        list.each { |c| @scheduler << c }

        @time_last = max_time_last
        @time_next = min
      end

      def collect(time)
        if time != @time_next
          raise BadSynchronisationError, "\ttime: #{time} should match time_next: #{@time_next}"
        end
        @time_last = time

        imm = if @scheduler.prefer_mass_reschedule?
          @scheduler.peek_simultaneous
        else
          @scheduler.pop_simultaneous
        end

        @parent_bag.clear unless @parent_bag.empty?
        i = 0
        while i < imm.size
          child = imm[i]
          @synchronize[child] = true
          output = child.collect(time)

          output.each do |port, payload|
            if child.is_a?(Simulator)
              port.changed
              port.notify_observers(port, payload)
            end

            # check internal coupling to get children who receive sub-bag of y
            j = 0
            ic = @model.internal_couplings(port)
            while j < ic.size
              dst = ic[j]
              receiver = dst.host.processor
              if child.is_a?(Coordinator)
                @influencees[receiver][dst].concat(payload)
              else
                @influencees[receiver][dst] << payload
              end
              @synchronize[receiver] = true
              j += 1
            end

            # check external coupling to form sub-bag of parent output
            j = 0
            oc = @model.output_couplings(port)
            while j < oc.size
              dst = oc[j]
              if child.is_a?(Coordinator)
                @parent_bag[dst].concat(payload)
              else
                @parent_bag[dst] << payload
              end
              j += 1
            end
          end
          i += 1
        end

        @parent_bag
      end

      def remainder(time, bag)
        bag.each do |port, sub_bag|
          # check external input couplings to get children who receive sub-bag of y
          i = 0
          ic = @model.input_couplings(port)
          while i < ic.size
            dst = ic[i]
            receiver = dst.host.processor
            @influencees[receiver][dst].concat(sub_bag)
            @synchronize[receiver] = true
            i += 1
          end
        end

        @synchronize.each_key do |receiver|
          sub_bag = @influencees[receiver]
          if @scheduler.prefer_mass_reschedule?
            receiver.remainder(time, sub_bag)
          else
            tn = receiver.time_next
            # before trying to cancel a receiver, test if time is not strictly
            # equal to its time_next. If true, it means that its model will
            # receiver either an internal_transition or a confluent transition,
            # and that the receiver is no longer in the scheduler
            @scheduler.delete(receiver) if tn < DEVS::INFINITY && time != tn
            tn = receiver.remainder(time, sub_bag)
            @scheduler.push(receiver) if tn < DEVS::INFINITY
          end
          sub_bag.clear
        end
        @scheduler.reschedule! if @scheduler.prefer_mass_reschedule?
        @synchronize.clear

        @time_last = time
        @time_next = min_time_next
      end
    end
  end
end
