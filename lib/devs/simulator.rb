module DEVS
  class Simulator < Processor
    def initialize(model, run_validations: false)
      super(model)
      @run_validations = run_validations
      @transition_count = Hash.new(0)
    end

    def transition_stats
      @transition_count
    end
  end
end
