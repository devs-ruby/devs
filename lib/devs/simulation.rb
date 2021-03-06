module DEVS
  # This class represent the interface to the simulation
  class Simulation
    include Logging
    include Enumerable

    attr_reader :duration, :time, :processor, :model

    # @!attribute [r] time
    #   @return [Numeric] Returns the current simulation time

    # @!attribute [r] start_time
    #   @return [Time] Returns the time at which the simulation started

    # @!attribute [rw] duration
    #   @return [Numeric] Returns the total duration of the simulation time

    # Returns a new {Simulation} instance.
    #
    # @param model [Model] the model hierarchy
    # @param scheduler [Symbol] the default scheduler to use
    # @param maintain_hierarchy [true,false] flatten the hierarchy
    # @param duration [Numeric] the duration of the simulation
    # @param formalism [Symbol] the formalism to use
    # @param run_validations [true,false] activate runtime model validations
    def initialize(
      model,
      scheduler: :ladder_queue,
      maintain_hierarchy: true,
      duration: DEVS::INFINITY,
      run_validations: false,
      formalism: :pdevs
    )
      @time = 0
      @lock = Mutex.new
      @model = if model.atomic?
        CoupledModel.new(:root_coupled_model) << model
      else
        model
      end

      @duration = duration
      @run_validations = run_validations
      self.namespace = formalism
      self.scheduler = scheduler

      # TODO either forbid this feature with cdevs or add a warning when using cdevs
      unless maintain_hierarchy
        time = Time.now
        direct_connect!
        DEVS.logger.info "  * Flattened modeling tree in #{Time.now - time} secs" if DEVS.logger
      end

      time = Time.now
      @processor = allocate_processors
      DEVS.logger.info "  * Allocated processors in #{Time.now - time} secs" if DEVS.logger
    end

    def inspect
      "<#{self.class}: status=\"#{status}\", time=#{time}, duration=#{@duration}>"
    end

    def time
      @lock.lock
      t = @time
      @lock.unlock
      t
    end
    alias_method :clock, :time

    def duration
      @lock.lock
      d = @duration
      @lock.unlock
      d
    end

    def duration=(v)
      @lock.lock
      @duration = v
      @lock.unlock
      v
    end

    def start_time
      @lock.synchronize { @start_time }
    end

    def final_time
      @lock.synchronize { @final_time }
    end

    # Returns <tt>true</tt> if the simulation is done, <tt>false</tt> otherwise.
    #
    # @return [Boolean]
    def done?
      @lock.synchronize { @time >= @duration }
    end

    # Returns <tt>true</tt> if the simulation is currently running,
    #   <tt>false</tt> otherwise.
    #
    # @return [Boolean]
    def running?
      @lock.synchronize { @start_time != nil } && !done?
    end

    # Returns <tt>true</tt> if the simulation is waiting to be started,
    #   <tt>false</tt> otherwise.
    #
    # @return [Boolean]
    def waiting?
      @lock.synchronize { @start_time == nil }
    end

    # Returns the simulation status: <tt>waiting</tt>, <tt>running</tt> or
    #   <tt>done</tt>.
    #
    # @return [Symbol] the simulation status
    def status
      if waiting?
        :waiting
      elsif running?
        :running
      elsif done?
        :done
      end
    end

    def percentage
      case status
      when :waiting then 0.0 * 100
      when :done    then 1.0 * 100
      when :running
        @lock.lock
        val = if @time > @duration
          1.0 * 100
        else
          @time.to_f / @duration.to_f * 100
        end
        @lock.unlock
        val
      end
    end

    def elapsed_secs
      case status
      when :waiting
        0.0
      when :done
        @lock.lock
        t = @final_time - @start_time
        @lock.unlock
        t
      when :running
        Time.now - self.start_time
      end
    end

    # Returns the number of transitions per model along with the total
    #
    # @return [Hash<Symbol, Fixnum>]
    def transition_stats
      if done?
        @transition_stats ||= (
          stats = {}
          hierarchy = @processor.children.dup
          i = 0
          while i < hierarchy.size
            child = hierarchy[i]
            if child.model.coupled?
              hierarchy.concat(child.children)
            else
              stats[child.model.name] = child.transition_stats
            end
            i+=1
          end
          total = Hash.new(0)
          stats.values.each { |h| h.each { |k, v| total[k] += v }}
          stats[:TOTAL] = total
          stats
        )
      end
    end

    def abort
      if running?
        info "Aborting simulation." if DEVS.logger
        self.time = @duration
        final_time = Time.now
        @lock.lock
        @final_time = final_time
        @lock.unlock
      end
    end

    def restart
      case status
      when :done
        @transition_stats = nil
        self.time = 0
        @start_time = nil
        @final_time = nil
      when :running
        info "Cannot restart, the simulation is currently running." if DEVS.logger
      end
    end

    # TODO error hook
    # Run the simulation in a new thread
    def simulate
      if waiting?
        simulable = @namespace::Simulable
        start_time = begin_simulation
        initialize_simulation
        while self.time < self.duration
          debug "* Tick at: #{self.time}, #{Time.now - start_time} secs elapsed" if DEVS.logger && DEVS.logger.debug?
          self.time = simulable.step(@processor, self.time)
        end
        end_simulation
      elsif DEVS.logger
        if running?
          error "The simulation already started at #{self.start_time} and is currently running."
        else
          error "The simulation is already done. Started at #{self.start_time} and finished at #{self.final_time} in #{elapsed_secs} secs."
        end
      end
      self
    end

    def each(&block)
      if waiting?
        if block_given?
          simulable = @namespace::Simulable
          start_time = begin_simulation
          initialize_simulation
          while time < self.duration
            debug "* Tick at: #{self.time}, #{Time.now - start_time} secs elapsed" if DEVS.logger && DEVS.logger.debug?
            self.time = simulable.step(@processor, self.time)
            yield(self)
          end
          end_simulation
        else
          return enum_for(:each, &block)
        end
      elsif DEVS.logger
        if running?
          error "The simulation already started at #{self.start_time} and is currently running."
        else
          error "The simulation is already done. Started at #{self.start_time} and finished at #{self.final_time} in #{elapsed_secs} secs."
        end
        nil
      end
    end

    def step
      simulable = @namespace::Simulable
      if waiting?
        initialize_simulation
        begin_simulation
        self.time
      elsif running?
        self.time = simulable.step(@processor, self.time)
        end_simulation if done?
        self.time
      else
        nil
      end
    end

    def generate_graph(path='model_hierarchy.dot')
      path << ".dot" if File.extname(path).empty?
      file = File.new(path, 'w+')
      file.puts "digraph"
      file.puts '{'
      file.puts "compound = true;"
      file.puts "rankdir = LR;"
      file.puts "node [shape = box];"

      fill_graph(file, @model)

      file.puts '}'
      file.close
    end

    private

    def initialize_simulation
      simulable = @namespace::Simulable
      Hooks.notifier.notify(:before_simulation_initialization_hook)
      self.time = simulable.initialize_state(@processor, self.time)
      Hooks.notifier.notify(:after_simulation_initialization_hook)
    end

    def allocate_processors(coupled = @model)
      processor = coupled.class.processor_for(@namespace).new(coupled, scheduler: @scheduler, namespace: @namespace, run_validations: @run_validations)
      coupled.each_child do |model|
        processor << if model.coupled?
          allocate_processors(model)
        else
          model.class.processor_for(@namespace).new(model, run_validations: @run_validations)
        end
      end
      processor
    end

    def namespace=(formalism)
      @namespace = case formalism
      when :cdevs then CDEVS
      when :pdevs then PDEVS
      else
        DEVS.logger.warn("formalism #{formalism} unknown, defaults to PDEVS") if DEVS.logger
        PDEVS
      end
    end

    def scheduler=(name)
      @scheduler = case name
      when :ladder_queue then LadderQueue
      when :binary_heap then BinaryHeap
      when :minimal_list then MinimalList
      when :sorted_list then SortedList
      when :splay_tree then SplayTree
      when :calendar_queue then CalendarQueue
      else
        DEVS.logger.warn("scheduler #{name} unknown, defaults to LadderQueue") if DEVS.logger
        LadderQueue
      end
    end

    # TODO Don't destruct the old hierarchy
    def direct_connect!
      models = @model.each_child.to_a
      children_list = []
      new_internal_couplings = Hash.new { |h, k| h[k] = [] }

      i = 0
      while i < models.size
        model = models[i]
        if model.coupled?
          # get internal couplings between atomics that we can reuse as-is in the root model
          model.each_internal_coupling do |src, dst|
            if src.host.atomic? && dst.host.atomic?
              new_internal_couplings[src] << dst
            end
          end
          model.each_child { |c| models << c }
        else
          children_list << model
        end
        i += 1
      end

      cm = @model
      cm.each_child.each { |c| cm.remove_child(c) }
      children_list.each { |c| cm << c }

      find_direct_couplings(cm) do |src, dst|
        new_internal_couplings[src] << dst
      end

      internal_couplings = cm.instance_variable_get(:@internal_couplings).clear
      internal_couplings.merge!(new_internal_couplings)
    end

    def fill_graph(graph, cm)
      cm.each_child do |model|
        name = model.to_s
        if model.coupled?
          graph.puts "subgraph \"cluster_#{name}\""
          graph.puts '{'
          graph.puts "label = \"#{name}\";"
          fill_graph(graph, model)
          model.each_internal_coupling do |src, dst|
            if src.host.atomic? && dst.host.atomic?
              graph.puts "\"#{src.host.name.to_s}\" -> \"#{dst.host.name.to_s}\" [label=\"#{src.name.to_s} → #{dst.name.to_s}\"];"
            end
          end
          graph.puts "};"
        else
          graph.puts "\"#{name}\" [style=filled];"
        end
      end

      find_direct_couplings(cm) do |src, dst|
        graph.puts "\"#{src.host.name.to_s}\" -> \"#{dst.host.name.to_s}\" [label=\"#{src.name.to_s} → #{dst.name.to_s}\"];"
      end if cm == @model
    end

    def find_direct_couplings(cm)
      couplings = []
      cm.each_coupling { |s,d| couplings << [s,d] }

      i = 0
      while i < couplings.size
        osrc, odst = couplings[i]
        if osrc.host.atomic? && odst.host.atomic?
          yield(osrc, odst) # found direct coupling
        elsif osrc.host.coupled? # eic
          route = [[osrc, odst]]
          j = 0
          while j < route.size
            rsrc, _ = route[j]
            rsrc.host.each_output_coupling_reverse(rsrc) do |src, dst|
              if src.host.coupled?
                route.push([src, dst])
              else
                couplings.push([src, odst])
              end
            end
            j += 1
          end
        elsif odst.host.coupled? # eoc
          route = [[osrc,odst]]
          j = 0
          while j < route.size
            _, rdst = route[j]
            rdst.host.each_input_coupling(rdst) do |src,dst|
              if dst.host.coupled?
                route.push([src, dst])
              else
                couplings.push([osrc, dst])
              end
            end
            j += 1
          end
        end
        i += 1
      end
    end

    def time=(v)
      @lock.lock
      @time = v
      @lock.unlock
      v
    end

    def begin_simulation
      t = Time.now
      @lock.lock
      @start_time = t
      info "*** Beginning simulation at #{@start_time} with duration: #{@duration}" if DEVS.logger
      @lock.unlock
      Hooks.notifier.notify(:before_simulation_hook)
      t
    end

    def end_simulation
      final_time = Time.now
      @lock.lock
      @final_time = final_time
      @lock.unlock

      if DEVS.logger
        info "*** Simulation ended at #{final_time} after #{elapsed_secs} secs."
        debug "* Transition stats : {"
        transition_stats.each { |k, v| debug "    #{k} => #{v}" }
        debug "* }"
        debug "* Running post simulation hook"
      end

      Hooks.notifier.notify(:after_simulation_hook)
    end
  end
end
