module DEVS
  module CDEVS
    # This module represent the interface with {Simulation}. It it responsible for
    # coordinating the simulation.
    module Simulable
      def initialize_state(root, time)
        root.initialize_processor(time)
      end
      module_function :initialize_state

      def step(root, time)
        root.internal_message(time)
        root.time_next
      end
      module_function :step
    end
  end
end
