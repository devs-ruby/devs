module DEVS
  class SimulationBuilder < CoupledBuilder
    attr_accessor :duration
    attr_reader :model

    def initialize(opts={}, &block)
      @opts = {
        formalism: :pdevs,
        scheduler: :ladder_queue,
        maintain_hierarchy: false,
        generate_graph: false,
        graph_file: 'model_hierarchy',
        graph_format: 'png',
        duration: DEVS::INFINITY
      }.merge(opts)

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

    def generate_graph!(file = nil, format = nil)
      @opts[:graph_file] = file if file
      @opts[:graph_format] = format if format
      @opts[:generate_graph] = true
    end

    def maintain_hierarchy!
      @opts[:maintain_hierarchy] = true
    end

    def duration(duration)
      @opts[:duration] = duration
    end
  end
end
