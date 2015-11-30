module DEVS
  module Classic
    # This module represent the interface with {Simulation}. It it responsible for
    # coordinating the simulation.
    module Simulable
      def initialize_state(time)
        init(time)
      end

      def step(time)
        internal_message(time)
        @time_next
      end
    end
  end
end

