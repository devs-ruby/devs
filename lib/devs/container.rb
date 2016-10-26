module DEVS
  # The {Container} mixin provides coupled models with several components and
  # coupling methods. The class must call {#initialize_container} during its
  # initialization in order to allocate instance variables.
  module Container
    attr_reader :children, :internal_couplings, :input_couplings,
                :output_couplings

    alias_method :components, :children

    # @!attribute [r] children
    #   This attribute returns an associative array of all its child models,
    #     composed of {AtomicModel}s or/and {CoupledModel}s, indexed by their
    #     names.
    #   @return [Hash<Symbol,Model>] Returns a list of all its child models

    # @!attribute [r] internal_couplings
    #   This attribute returns a list of all its <i>internal couplings</i> (IC).
    #   An internal coupling connects two {#children}: an output {Port} of
    #   the first {Model} is thereby connected to an input {Port} of the
    #   second child.
    #   @see #add_internal_coupling
    #   @return [Array<Port>] Returns a list of all its
    #     <i>internal couplings</i> (IC)

    # @!attribute [r] input_couplings
    #   This attribute returns a list of all its
    #   <i>external input couplings</i> (EIC). Each of them links one of all
    #   {#children} to one of its own {Port}. More precisely, it links an
    #   input {Port} of <i>self</i> to an input {Port} of the child.
    #   @see #add_external_input_coupling
    #   @return [Array<Port>] Returns a list of all its
    #     <i>external input couplings</i> (EIC)

    # @!attribute [r] output_couplings
    #   This attribute returns a list of all its
    #   <i>external output couplings</i> (EOC). Each of them links one of all
    #   {#children} to one of its own {Port}. More precisely, it links an
    #   output {Port} of the child to an output {Port} of <i>self</i>.
    #   @see #add_external_input_coupling
    #   @return [Array<Port>] Returns a list of all its
    #     <i>external output couplings</i> (EOC)

    def initialize_container
      @children = {}
      @input_couplings = Hash.new { |h, k| h[k] = [] }
      @output_couplings = Hash.new { |h, k| h[k] = [] }
      @internal_couplings = Hash.new { |h, k| h[k] = [] }
    end
    protected :initialize_container

    def internal_couplings(port = nil)
      if port.nil?
        @internal_couplings
      else
        @internal_couplings[port]
      end
    end

    def output_couplings(port = nil)
      if port.nil?
        @output_couplings
      else
        @output_couplings[port]
      end
    end

    def input_couplings(port = nil)
      if port.nil?
        @input_couplings
      else
        @input_couplings[port]
      end
    end

    # Append the specified child to children list if it's not already there
    #
    # @param child [Model] the new child
    # @return [Model] returns self
    def <<(child)
      @children[child.name] = child
      self.processor << child.processor
      self
    end
    alias_method :add_child, :<<

    # Deletes the specified child from children list
    #
    # @param child [String,Symbol] the child to remove
    # @return [Model] the deleted child
    def remove_child(name)
      child = @children.delete(name.to_sym)
      self.processor.remove_child(child.processor) if child
    end

    # Returns the children names
    #
    # @return [Array<String, Symbol>] the children names
    def children_names; @children.keys; end

    #def children; children.values; end

    # Find the component {Model} identified by the given <tt>name</tt>
    #
    # @param name [String, Symbol] the component name
    # @return [Model] the matching component, nil otherwise
    def [](name)
      @children[name.to_sym]
    end
    alias_method :find_child_by_name, :[]

    # Calls <tt>block</tt> once for each child in <tt>self</tt>, passing that
    # element as a parameter.
    #
    # If no block is given, an {Enumerator} is returned instead.
    # @overload each_child
    #   @yieldparam child [Model] the child that is yielded
    #   @return [nil]
    # @overload each_child
    #   @return [Enumerator<Model>]
    def each_child
      return @children.enum_for(:each_child) unless block_given?
      @children.each_value { |child| yield(child) }
    end

    # Calls <tt>block</tt> once for each external input coupling (EIC) in
    # {#input_couplings}, passing that element as a parameter. If a port is
    # given, it is used to filter the couplings having this port as a source.
    #
    # @param port [Port, nil] the source port or nil
    # @yieldparam source_port [Port] the source port
    # @yieldparam destination_port [Port] the destination port
    def each_input_coupling(port = nil)
      return enum_for(:each_input_coupling) unless block_given?
      if port.nil?
        @input_couplings.each { |s,ary| ary.each { |d| yield(s,d) }}
      else
        i = 0
        ary = @input_couplings[port]
        while i < ary.size
          yield(port, ary[i])
          i += 1
        end
      end
    end

    # Calls <tt>block</tt> once for each internal coupling (IC) in
    # {#internal_couplings}, passing that element as a parameter. If a port is
    # given, it is used to filter the couplings having this port as a source.
    #
    # @param port [Port, nil] the source port or nil
    # @yieldparam source_port [Port] the source port
    # @yieldparam destination_port [Port] the destination port
    def each_internal_coupling(port = nil)
      return enum_for(:each_internal_coupling) unless block_given?
      if port.nil?
        @internal_couplings.each { |s,ary| ary.each { |d| yield(s,d) }}
      else
        i = 0
        ary = @internal_couplings[port]
        while i < ary.size
          yield(port, ary[i])
          i += 1
        end
      end
    end

    # Calls <tt>block</tt> once for each external output coupling (EOC) in
    # {#output_couplings}, passing that element as a parameter. If a port is
    # given, it is used to filter the couplings having this port as a source.
    #
    # @param port [Port, nil] the source port or nil
    # @yieldparam source_port [Port] the source port
    # @yieldparam destination_port [Port] the destination port
    def each_output_coupling(port = nil)
      return enum_for(:each_output_coupling) unless block_given?
      if port.nil?
        @output_couplings.each { |s,ary| ary.each { |d| yield(s,d) }}
      else
        i = 0
        ary = @output_couplings[port]
        while i < ary.size
          yield(port, ary[i])
          i += 1
        end
      end
    end

    # Calls <tt>block</tt> once for each coupling in passing that element as a
    # parameter. If a port is given, it is used to filter the couplings having
    # this port as a source.
    #
    # @param ary [Array] the array of couplings, defaults to {#couplings}
    # @param port [Port, nil] the source port or nil
    # @yieldparam source_port [Port] the source port
    # @yieldparam destination_port [Port] the destination port
    def each_coupling(port = nil, &block)
      return enum_for(:each_coupling) unless block
      each_input_coupling(port, &block)
      each_internal_coupling(port, &block)
      each_output_coupling(port, &block)
    end

    # TODO doc
    def each_input_coupling_reverse(port)
      return enum_for(:each_coupling_reverse) unless block_given?
      @input_couplings.each do |src, ary|
        ary.each { |dst| yield(src,dst) if dst == port }
      end
    end

    # TODO doc
    def each_internal_coupling_reverse(port)
      return enum_for(:each_coupling_reverse) unless block_given?
      @internal_couplings.each do |src, ary|
        ary.each { |dst| yield(src,dst) if dst == port }
      end
    end

    # TODO doc
    def each_output_coupling_reverse(port)
      return enum_for(:each_coupling_reverse) unless block_given?
      @output_couplings.each do |src, ary|
        ary.each { |dst| yield(src,dst) if dst == port }
      end
    end

    # Adds an external input coupling (EIC) to self. Establish a relation between
    # a self input {Port} and an input {Port} of one of self's children.
    #
    # If the ports aren't provided, they will be automatically generated.
    #
    # @param child [Model, String, Symbol] the child or its name
    # @param input_port [Port, String, Symbol] specify the self input port or
    #   its name to connect to the child_port.
    # @param child_port [Port, String, Symbol] specify the child's input port
    #   or its name.
    def add_external_input_coupling(child, input_port = nil, child_port = nil)
      child = ensure_child(child)

      if !input_port.nil? && !child_port.nil?
        input_port = find_or_create_input_port_if_necessary(input_port)
        child_port = child.find_or_create_input_port_if_necessary(child_port)

        #coupling = Coupling.new(input_port, child_port, :eic)
        @input_couplings[input_port] << child_port
      end
    end
    alias_method :add_external_input, :add_external_input_coupling

    # Adds an external output coupling (EOC) to self. Establish a relation
    # between an output {Port} of one of self's children and one of self's
    # output ports.
    #
    # If the ports aren't provided, they will be automatically generated.
    #
    # @param child [Model, String, Symbol] the child or its name
    # @param output_port [Port, String, Symbol] specify the self output port or
    #   its name to connect to the child_port.
    # @param child_port [Port, String, Symbol] specify the child's output port
    #   or its name.
    def add_external_output_coupling(child, output_port = nil, child_port = nil)
      child = ensure_child(child)

      if !output_port.nil? && !child_port.nil?
        output_port = find_or_create_output_port_if_necessary(output_port)
        child_port = child.find_or_create_output_port_if_necessary(child_port)

        #coupling = Coupling.new(child_port, output_port, :eoc)
        @output_couplings[child_port] << output_port
      end
    end
    alias_method :add_external_output, :add_external_output_coupling

    # Adds an internal coupling (IC) to self. Establish a relation between an
    # output {Port} of a first child and the input {Port} of a second child.
    #
    # If the ports parameters are ommited, they will be automatically
    # generated. Otherwise, the specified ports will be used. If a name is
    # given instead
    #
    # @param a [Model, String, Symbol] the first child or its name
    # @param b [Model, String, Symbol] the second child or its name
    # @param output_port [Port, String, Symbol] a's output port or its name
    # @param input_port [Port, String, Symbol] b's input port ot its name
    # @raise [FeedbackLoopError] if both given children are the same. Direct
    #   feedback loops are not allowed, i.e, no output port of a component may
    #   be connected to an input port of the same component
    def add_internal_coupling(a, b, output_port = nil, input_port = nil)
      a = ensure_child(a)
      b = ensure_child(b)
      raise FeedbackLoopError, "#{a} must be different than #{b}" if a.equal?(b)

      output_port = a.find_or_create_output_port_if_necessary(output_port)
      input_port = b.find_or_create_input_port_if_necessary(input_port)

      #coupling = Coupling.new(output_port, input_port, :ic)
      @internal_couplings[output_port] << input_port
    end

    def remove_coupling(src, dst, src_port, dst_port)
      if src == @name || src == self
        child = ensure_child(dst)
        remove_input_coupling(@input_ports[src_port], child.input_ports[dst_port])
      elsif dst == @name || dst == self
        child = ensure_child(src)
        remove_output_coupling(child.output_ports[src_port], @output_ports[dst_port])
      else
        a = ensure_child(src)
        b = ensure_child(dst)
        remove_internal_coupling(a.output_ports[src_port], b.input_ports[dst_port])
      end
    end

    def remove_internal_coupling(src_port, dst_port)
      couplings = @internal_couplings[src_port]
      i = couplings.index { |port| port == dst_port }
      couplings.delete_at(i)
    end

    def remove_input_coupling(src_port, dst_port)
      couplings = @input_couplings[src_port]
      i = couplings.index { |port| port == dst_port }
      couplings.delete_at(i)
    end

    def remove_output_coupling(src_port, dst_port)
      couplings = @output_couplings[src_port]
      i = couplings.index { |port| port == dst_port }
      couplings.delete_at(i)
    end

    def ensure_child(child)
      child = self[child] unless child.is_a?(Model)
      raise NoSuchChildError, "the child '#{child}' doesn't exist" if child.nil?
      child
    end
  end
end
