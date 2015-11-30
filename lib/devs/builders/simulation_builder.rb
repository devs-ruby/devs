module DEVS
  class SimulationBuilder < CoupledBuilder
    attr_accessor :duration
    attr_reader :simulation

    def initialize(opts={}, &block)
      @build_start_time = Time.now
      DEVS.logger.info("*** Building simulation at #{@build_start_time}") if DEVS.logger
      @opts = {
        formalism: :pdevs,
        scheduler: :ladder_queue,
        maintain_hierarchy: false,
        generate_graph: false,
        graph_file: 'model_hierarchy',
        graph_format: 'png'
      }.merge(opts)

      namespace = case @opts[:formalism]
      when :pdevs then SequentialParallel
      when :cdevs then Classic
      else
        DEVS.logger.warn("formalism #{@opts[:formalism]} unknown, defaults to PDEVS") if DEVS.logger
        SequentialParallel
      end

      Coordinator.send(:include, namespace::CoordinatorImpl) unless Coordinator.include?(namespace::CoordinatorImpl)
      Simulator.send(:include, namespace::SimulatorImpl) unless Simulator.include?(namespace::SimulatorImpl)

      @model = CoupledModel.new(:root_coupled_model)
      @processor = Coordinator.new(@model)
      @processor.singleton_class.send(:include, namespace::Simulable)
      @duration = DEVS::INFINITY
      scheduler(@opts[:scheduler])
      instance_eval(&block) if block
    end

    def build
      direct_connect! unless @opts[:maintain_hierarchy]
      generate_graph(@opts[:graph_file], @opts[:graph_format]) if @opts[:generate_graph]
      @simulation = Simulation.new(@processor, @duration, @build_start_time)
    end

    def scheduler(name)
      DEVS.scheduler = case name
      when :ladder_queue then LadderQueue
      when :binary_heap then BinaryHeap
      when :minimal_list then MinimalList
      when :sorted_list then SortedList
      when :splay_tree then SplayTree
      when :calendar_queue then CalendarQueue
      else
        DEVS.logger.warn("scheduler #{@opts[:scheduler]} unknown, defaults to LadderQueueScheduler") if DEVS.logger
        LadderQueue
      end
    end

    def generate_graph!(file = nil, format = nil)
      @graph_file = file if file
      @graph_format = format if format
      @generate_graph = true
    end

    def maintain_hierarchy!
      @maintain_hierarchy = true
    end

    def duration(duration)
      @duration = duration
    end

    def direct_connect!
      rm = @model
      folded = rm.children
      unfolded = []
      sub_ic = []
      i = 0
      root_threshold = folded.size

      while i < folded.count
        m = folded[i]

        if m.coupled?
          sub_ic.concat(m.internal_couplings.select { |c|
            c.source.atomic? && c.destination.atomic?
          })
          folded.concat(m.children)
        else
          unfolded << m if i > root_threshold-1
        end

        i += 1
      end

      unfolded.each { |m| rm << m; rm.processor << m.processor }
      adjust_couplings!(rm, rm.internal_couplings + sub_ic)

      rm.children.each do |m|
        if m.coupled?
          rm.remove_child(m)
          rm.processor.remove_child(m.processor)
        end
      end
      rm.couplings.each { |c| rm.remove_coupling(c) if c.source.coupled? || c.destination.coupled? }
    end
    private :direct_connect!

    def adjust_couplings!(rm, couplings)
      couplings = Array.new(couplings)
      j = 0

      while j < couplings.count
        c1 = couplings[j]
        if c1.source.coupled? # eoc
          i = 0
          route = [c1]
          while i < route.count
            tmp = route[i]
            src = tmp.source
            port_source = tmp.port_source

            (src.internal_couplings + src.output_couplings).each do |ci|
              if ci.destination_port == port_source
                if ci.source.coupled?
                  route << ci
                else
                  if c1.destination.coupled?
                    couplings << Coupling.new(ci.port_source, c1.destination_port, :ic)
                  else
                    rm.add_internal_coupling(ci.source, c1.destination, ci.port_source, c1.destination_port)
                  end
                end
              end
            end

            i += 1
          end
        elsif c1.destination.coupled? # eic
          i = 0
          route = [c1]
          while i < route.count
            tmp = route[i]
            dest = tmp.destination

            dest.each_coupling(dest.internal_couplings + dest.input_couplings, tmp.destination_port) do |ci|
              if ci.destination.coupled?
                route << ci
              else
                if c1.source.coupled?
                  couplings << Coupling.new(c1.port_source, ci.destination_port, :ic)
                else
                  rm.add_internal_coupling(c1.source, ci.destination, c1.port_source, ci.destination_port)
                end
              end
            end

            i += 1
          end
        else
          # source and destination are atomics
          rm.add_internal_coupling(c1.source, c1.destination, c1.port_source,
                                   c1.destination_port)
        end
        j += 1
      end
    end
    private :adjust_couplings!

    def generate_graph(file, format)
      # require optional dependency
      require 'graph'
      graph = Graph.new
      graph.graph_attribs << Graph::Attribute.new('compound = true')
      graph.boxes
      graph.rotate
      fill_graph(graph, @model)
      graph.save(file, format)
    rescue LoadError
      DEVS.logger.warn "Unable to generate a graph representation of the "\
                       "model hierarchy. Please install graphviz on your "\
                       "system and 'gem install graph'."
    end
    private :generate_graph

    def fill_graph(graph, cm)
      port_node = graph.fontsize(9)
      input_port_node = port_node + graph.midnightblue
      output_port_node = port_node + graph.tomato
      port_link = Graph::Attribute.new('arrowhead = none') + Graph::Attribute.new('weight = 10')

      cm.each do |model|
        name = model.to_s

        if model.coupled?
          subgraph = graph.cluster(name)
          subgraph.label name
          fill_graph(subgraph, model)
        else
          graph.node(name)
        end

        (model.input_ports + model.output_ports).each do |port|
          port_name = "#{name}@#{port.name.to_s}"
          node = graph.node(port_name)
          node.attributes << if port.input?
            input_port_node
          else
            output_port_node
          end
          node.label "@#{port.name.to_s}"
          if model.atomic?
            node.attributes << graph.circle
            edge = graph.edge(name, port_name)
            edge.attributes << port_link
            if port.output?
              edge.attributes << Graph::Attribute.new('arrowtail = odot') << Graph::Attribute.new('dir = both')
            end
          else
            node.attributes << graph.doublecircle
          end
        end
      end

      # add invisible node
      graph.invisible << graph.node("#{cm.name}_invisible")

      (cm.internal_couplings + cm.input_couplings + cm.output_couplings).each do |coupling|
        from = "#{coupling.source.name}@#{coupling.port_source.name.to_s}"
        to = "#{coupling.destination.name}@#{coupling.destination_port.name.to_s}"
        edge = graph.edge(from, to)
        edge.attributes << graph.dashed
      end
    end
    private :fill_graph
  end
end
