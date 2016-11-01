module DEVS
  # The {Container} mixin provides coupled models with several components and
  # coupling methods. The class must call {#initialize_container} during its
  # initialization in order to allocate instance variables.
  module Container

    # Returns an associative array of all its child models,
    # composed of {AtomicModel}s or/and {CoupledModel}s, indexed by their
    # names.
    # @return [Hash<Symbol,Model>] Returns a list of all its child models
    protected def children
      @children ||= {}
    end

    # Represents all <i>internal couplings</i> (IC).
    protected def _internal_couplings
      @internal_couplings ||= Hash.new { |h, k| h[k] = [] }
    end

    # Represents all <i>external output couplings</i> (EOC).
    protected def _output_couplings
      @output_couplings ||= Hash.new { |h, k| h[k] = [] }
    end

    # Represents all <i>external input couplings</i> (EIC).
    protected def _input_couplings
      @input_couplings ||= Hash.new { |h, k| h[k] = [] }
    end

    def internal_couplings(port)
      _internal_couplings[port]
    end

    def output_couplings(port)
      _output_couplings[port]
    end

    def input_couplings(port)
      _input_couplings[port]
    end

    # Append the specified model to childrens.
    #
    # @param child [Model] the new child
    # @return [Model] returns self
    def <<(child)
      children[child.name] = child
      self
    end
    alias_method :add_child, :<<

    # Deletes the specified child from children list
    #
    # @param child [String,Symbol] the child to remove
    # @return [Model] the deleted child
    def remove_child(name)
      children.delete(name)
    end

    # Returns the children names
    #
    # @return [Array<String, Symbol>] the children names
    def children_names
      children.keys
    end

    # Find the component {Model} identified by the given <tt>name</tt>
    #
    # @param name [String, Symbol] the component name
    # @return [Model] the matching component, nil otherwise
    def [](name)
      children[name.to_sym]
    end

    def has_child?(child)
      child = child.name if child.is_a?(Model)
      children.has_key?(child)
    end

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
      return children.enum_for(:each_value) unless block_given?
      children.each_value { |child| yield(child) }
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
        _input_couplings.each { |s,ary| ary.each { |d| yield(s,d) }}
      else
        i = 0
        ary = _input_couplings[port]
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
        _internal_couplings.each { |s,ary| ary.each { |d| yield(s,d) }}
      else
        i = 0
        ary = _internal_couplings[port]
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
        _output_couplings.each { |s,ary| ary.each { |d| yield(s,d) }}
      else
        i = 0
        ary = _output_couplings[port]
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
      return enum_for(:each_input_coupling_reverse) unless block_given?
      _input_couplings.each do |src, ary|
        ary.each { |dst| yield(src,dst) if dst == port }
      end
    end

    # TODO doc
    def each_internal_coupling_reverse(port)
      return enum_for(:each_internal_coupling_reverse) unless block_given?
      _internal_couplings.each do |src, ary|
        ary.each { |dst| yield(src,dst) if dst == port }
      end
    end

    # TODO doc
    def each_output_coupling_reverse(port)
      return enum_for(:each_output_coupling_reverse) unless block_given?
      _output_couplings.each do |src, ary|
        ary.each { |dst| yield(src,dst) if dst == port }
      end
    end

    # TODO doc
    def each_coupling_reverse(port)
      return enum_for(:each_coupling_reverse) unless block_given?
      each_input_coupling_reverse(port, &block)
      each_internal_coupling_reverse(port, &block)
      each_output_coupling_reverse(port, &block)
    end

    # Adds a coupling to self between two ports.
    #
    # Depending on *p1* and *to* hosts, the function will create an internal
    # coupling (IC), an external input coupling (EIC) or an external output
    # coupling (EOC).
    #
    # @overload attach(p1, to:)
    #   @param p1 [Port] the sender port of the coupling
    #   @param to [Port] the receiver port of the coupling
    # @overload attach(p1, to:, between:, and:)
    #   @param p1 [Port,Symbol,String] the sender port of the coupling
    #   @param to [Port,Symbol,String] the receiver port of the coupling
    #   @param between [Coupleable,Symbol,String] the sender
    #   @param and [Coupleable,Symbol,String] the receiver
    #
    # @raise [FeedbackLoopError] if *p1* and *p2* hosts are the same child
    #   when constructing an internal coupling. Direct feedback loops are not
    #   allowed, i.e, no output port of a component may be connected to an input
    #   port of the same component.
    # @raise [InvalidPortTypeError] if given ports are not of the expected IO
    #   modes (:input or :output).
    # @raise [InvalidPortHostError] if no coupling can be established from
    #   given ports hosts.
    #
    # @note If given port names *p1* and *p2* doesn't exist within their
    #   host (respectively *sender* and *receiver*), they will be automatically
    #   generated.
    # @example Attach two ports together to form a new coupling
    #   attach component1.output_port(:out) to: component2.input_port(:in) # IC
    #   attach self.input_port(:in) to: child.input_port(:in) # EIC
    #   attach child.output_port(:out) to: self.output_port(:out) # EOC
    # @example Attach specified ports and components to form a new coupling
    #   attach :out, to: :in, between: :component1, and: :component2
    #   attach :in, to: :in, between: self, and: child
    def attach(p1, to:, between: nil, and: nil)
      p2 = to
      sender = between
      # use binding#local_variable_get because 'and:' keyword argument clashes
      # with the language reserved keyword.
      receiver = binding.local_variable_get(:and)

      raise ArgumentError.new("'between:' keyword was omitted, 'p1' should be a Port.") if sender.nil? && !p1.is_a?(Port)
      raise ArgumentError.new("'and:' keyword was omitted, 'to:' should be a Port") if receiver.nil? && !p2.is_a?(Port)

      a = if p1.is_a?(Port) then p1.host
      elsif sender.is_a?(Coupleable) then sender
      elsif sender == @name then self
      else self[sender]; end

      b = if p2.is_a?(Port) then p2.host
      elsif receiver.is_a?(Coupleable) then receiver
      elsif receiver == @name then self
      else self[receiver]; end

      if has_child?(a) && has_child?(b) # IC
        p1 = a.output_port(p1) unless p1.is_a?(Port)
        p2 = b.input_port(p2) unless p2.is_a?(Port)
        raise InvalidPortTypeError.new unless p1.output? && p2.input?
        raise FeedbackLoopError.new("#{a} must be different than #{b}") if a.object_id == b.object_id
        _internal_couplings[p1] << p2
      elsif a == self && has_child?(b)  # EIC
        p1 = a.input_port(p1) unless p1.is_a?(Port)
        p2 = b.input_port(p2) unless p2.is_a?(Port)
        raise InvalidPortTypeError.new unless p1.input? && p2.input?
        _input_couplings[p1] << p2
      elsif has_child?(a) && b == self  # EOC
        p1 = a.output_port(p1) unless p1.is_a?(Port)
        p2 = b.output_port(p2) unless p2.is_a?(Port)
        raise InvalidPortTypeError.new unless p1.output? && p2.output?
        _output_couplings[p1] << p2
      else
        raise InvalidPortHostError.new("Illegal coupling between #{p1} and #{p2}")
      end
    end

    # Adds an external input coupling (EIC) to self. Establish a relation
    # between a self input port and a child input port.
    #
    # @param myport [String,Symbol] the source input port of the external input coupling
    # @param to [String,Symbol] the destination input port of the external input coupling
    # @param of [Coupleable,String,Symbol] the component that will receive inputs
    #
    # @note If given port names *myport* and *iport* doesn't exist within their
    #   host (respectively *self* and *child*), they will be automatically
    #   generated.
    # @example
    #   attach_input :in, to: :in, of: child
    # @example
    #   attach_input :in, to: :in, of: :my_component
    def attach_input(myport, to:, of:)
      receiver = of.is_a?(Coupleable) ? of : self[of]
      p1 = self.find_or_create_input_port_if_necessary(myport)
      p2 = receiver.find_or_create_input_port_if_necessary(to)
      attach(p1, to: p2)
    end

    # Adds an external output coupling (EOC) to self. Establish a relation
    # between an output port of one of self's children and one of self's
    # output ports.
    #
    # @param oport [String,Symbol] the source output port of the external output coupling
    # @param of [Coupleable,String,Symbol] the component that will send outputs
    # @param to [String,Symbol] the destination port that will forward outputs
    #
    # @note If given port names *oport* and *myport* doesn't exist within their
    #   host (respectively *child* and *self*), they will be automatically
    #   generated.
    # @example
    #   attach_output :out, of: child, to: :out
    def attach_output(oport, of:, to:)
      sender = of.is_a?(Coupleable) ? of : self[of]
      p1 = sender.find_or_create_output_port_if_necessary(oport)
      p2 = self.find_or_create_output_port_if_necessary(to)
      attach(p1, to: p2)
    end

    # Deletes a coupling between given ports and components from *self*.
    #
    # @overload detach(p1, from:)
    #   @param p1 [Port] the source port of the coupling
    #   @param from [Port] the destination port of the coupling
    #
    # @overload detach(p1, from:, between:, and:)
    #   @param p1 [Port,Symbol,String] the source port of the coupling
    #   @param from [Port,Symbol,String] the destination port of the coupling
    #   @param between [Coupleable,Symbol,String] the sender of the coupling
    #   @param and [Coupleable,Symbol,String] the receiver of the coupling
    #
    # @return [true,false] if successful
    #
    # @example Detach two ports from each other
    #   detach component1.output_port(:out) from: component2.input_port(:in) #IC
    #   detach self.input_port(:in) from: child.input_port(:in) # EIC
    #   detach child.output_port(:out) from: self.output_port(:out) # EOC
    # @example Detach specified ports and components from each other
    #   detach :out, from: :in, between: :component1, and: :component2
    #   detach :in, from: :in, between: self, and: child
    def detach(p1, from:, between: nil, and: nil)
      p2 = from
      sender = between
      # use binding#local_variable_get because 'and:' keyword argument clashes
      # with the language reserved keyword.
      receiver = binding.local_variable_get(:and)

      raise ArgumentError.new("'between:' keyword was omitted, 'p1' should be a Port.") if sender.nil? && !p1.is_a?(Port)
      raise ArgumentError.new("'and:' keyword was omitted, 'from:' should be a Port") if receiver.nil? && !p2.is_a?(Port)

      a = if p1.is_a?(Port) then p1.host
      elsif sender.is_a?(Coupleable) then sender
      elsif sender == @name then self
      else self[sender]; end

      b = if p2.is_a?(Port) then p2.host
      elsif receiver.is_a?(Coupleable) then receiver
      elsif receiver == @name then self
      else self[receiver]; end

      if has_child?(a) && has_child?(b) # IC
        _internal_couplings[p1].delete(p2) != nil
      elsif a == self && has_child?(b)  # EIC
        _input_couplings[p1].delete(p2) != nil
      elsif has_child?(a) && b == self  # EOC
        _output_couplings[p1].delete(p2) != nil
      else
        false
      end
    end

    # TODO Add #detach_input and #detach_output when defined in Quartz

    # @deprecated Use {#attach_input} or {#attach} instead.
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

        _input_couplings[input_port] << child_port
      end
    end
    alias_method :add_external_input, :add_external_input_coupling

    # @deprecated Use {#attach_output} or {#attach} instead.
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

        _output_couplings[child_port] << output_port
      end
    end
    alias_method :add_external_output, :add_external_output_coupling

    # @deprecated Use {#attach} or {#attach} instead.
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

      _internal_couplings[output_port] << input_port
    end

    # @deprecated Use {#detach} instead.
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

    # @deprecated Use {#detach} instead.
    def remove_internal_coupling(src_port, dst_port)
      couplings = @internal_couplings[src_port]
      i = couplings.index { |port| port == dst_port }
      couplings.delete_at(i)
    end

    # @deprecated Use {#detach} instead.
    def remove_input_coupling(src_port, dst_port)
      couplings = @input_couplings[src_port]
      i = couplings.index { |port| port == dst_port }
      couplings.delete_at(i)
    end

    # @deprecated Use {#detach} instead.
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
