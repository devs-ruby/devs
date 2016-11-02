module DEVS
  class SimulationBuilder < CoupledBuilder
    attr_accessor :duration
    attr_reader :model

    # Returns a new {SimulationBuilder} instance
    #
    # @param model [Model] the model hierarchy
    # @param scheduler [Symbol] the default scheduler to use
    # @param maintain_hierarchy [true,false] flatten the hierarchy
    # @param duration [Numeric] the duration of the simulation
    # @param formalism [Symbol] the formalism to use
    # @param run_validations [true,false] activate runtime model validations
    def initialize(**kwargs, &block)
      @opts = kwargs
      t1 = Time.now
      DEVS.logger.info("*** Building model hierarchy at #{t1}") if DEVS.logger
      @model = CoupledModel.new(:root_coupled_model)
      instance_eval(&block) if block
      t2 = Time.now
      elapsed_secs = t2 - t1
      DEVS.logger.info "*** Builded model hierarchy at #{t2} after #{elapsed_secs} secs." if DEVS.logger
    end

    def build
      DEVS::Simulation.new(@model, @opts)
    end

    def scheduler(name)
      @opts[:scheduler] = name
    end

    def maintain_hierarchy!
      @opts[:maintain_hierarchy] = true
    end

    def duration(duration)
      @opts[:duration] = duration
    end

    def run_validations!
      @opts[:run_validations] = true
    end
  end
end
