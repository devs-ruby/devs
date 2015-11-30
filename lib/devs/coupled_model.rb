module DEVS
  # This class represent a DEVS coupled model.
  class CoupledModel < Model
    include Enumerable

    attr_reader :children, :internal_couplings, :input_couplings,
                :output_couplings

    alias_method :components, :children

    # @!attribute [r] children
    #   This attribute returns a list of all its child models, composed of
    #   {AtomicModel}s or/and {CoupledModel}s.
    #   @return [Array<Model>] Returns a list of all its child models

    # @!attribute [r] internal_couplings
    #   This attribute returns a list of all its <i>internal couplings</i> (IC).
    #   An internal coupling connects two {#children}: an output {Port} of
    #   the first {Model} is thereby connected to an input {Port} of the
    #   second child.
    #   @see #add_internal_coupling
    #   @return [Array<Coupling>] Returns a list of all its
    #     <i>internal couplings</i> (IC)

    # @!attribute [r] input_couplings
    #   This attribute returns a list of all its
    #   <i>external input couplings</i> (EIC). Each of them links one of all
    #   {#children} to one of its own {Port}. More precisely, it links an
    #   input {Port} of <i>self</i> to an input {Port} of the child.
    #   @see #add_external_input_coupling
    #   @return [Array<Coupling>] Returns a list of all its
    #     <i>external input couplings</i> (EIC)

    # @!attribute [r] output_couplings
    #   This attribute returns a list of all its
    #   <i>external output couplings</i> (EOC). Each of them links one of all
    #   {#children} to one of its own {Port}. More precisely, it links an
    #   output {Port} of the child to an output {Port} of <i>self</i>.
    #   @see #add_external_input_coupling
    #   @return [Array<Coupling>] Returns a list of all its
    #     <i>external output couplings</i> (EOC)

    class << self
      attr_accessor :counter
    end
    @counter = 0

    # Returns a new instance of {CoupledModel}
    #
    # @param name [String, Symbol] the name of the model
    def initialize(name = nil)
      super(name)
      CoupledModel.counter += 1
      @name = :"#{self.class.name || 'CoupledModel'}#{CoupledModel.counter}" unless @name
      @children = {}
      @internal_couplings = Hash.new { |h, k| h[k] = [] }
      @input_couplings = Hash.new { |h, k| h[k] = [] }
      @output_couplings = Hash.new { |h, k| h[k] = [] }
    end

    # Returns a list of all its couplings.
    #
    # @return [Array<Coupling>] the list of couplings
    def couplings(port = nil)
      if port.nil?
        @internal_couplings.values
            .concat(@input_couplings.values)
            .concat(@output_couplings.values)
            .flatten!
      else
        Array.new(@internal_couplings[port])
            .concat(@input_couplings[port])
            .concat(@output_couplings[port])
            .flatten!
      end || []
    end

    def internal_couplings(port = nil)
      if port.nil?
        @internal_couplings.values.flatten! || []
      else
        @internal_couplings[port]
      end
    end

    def output_couplings(port = nil)
      if port.nil?
        @output_couplings.values.flatten! || []
      else
        @output_couplings[port]
      end
    end

    def input_couplings(port = nil)
      if port.nil?
        @input_couplings.values.flatten! || []
      else
        @input_couplings[port]
      end
    end

    # Returns a boolean indicating if <tt>self</tt> is a coupled model
    #
    # @return [true]
    def coupled?
      true
    end

    # Append the specified child to children list if it's not already there
    #
    # @param child [Model] the new child
    # @return [Model] the added child
    def <<(child)
      @children[child.name] = child
    end
    alias_method :add_child, :<<

    # Deletes the specified child from children list
    #
    # @param child [Model] the child to remove
    # @return [Model] the deleted child
    def remove_child(child)
      @children.delete(child.name)
    end

    # Returns the children names
    #
    # @return [Array<String, Symbol>] the children names
    def children_names; @children.keys; end

    def children; @children.values; end

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
    # @overload each
    #   @yieldparam child [Model] the child that is yielded
    #   @return [nil]
    # @overload each
    #   @return [Enumerator<Model>]
    def each
      return @children.enum_for(:each) unless block_given?
      @children.each_value { |child| yield(child) }
    end

    # Calls <tt>block</tt> once for each external input coupling (EIC) in
    # {#input_couplings}, passing that element as a parameter. If a port is
    # given, it is used to filter the couplings having this port as a source.
    #
    # @param port [Port, nil] the source port or nil
    # @yieldparam coupling [Coupling] the coupling that is yielded
    def each_input_coupling(port = nil, &block)
      each_coupling(@input_couplings, port, &block)
    end

    # Calls <tt>block</tt> once for each internal coupling (IC) in
    # {#internal_couplings}, passing that element as a parameter. If a port is
    # given, it is used to filter the couplings having this port as a source.
    #
    # @param port [Port, nil] the source port or nil
    # @yieldparam coupling [Coupling] the coupling that is yielded
    def each_internal_coupling(port = nil, &block)
      each_coupling(@internal_couplings, port, &block)
    end

    # Calls <tt>block</tt> once for each external output coupling (EOC) in
    # {#output_couplings}, passing that element as a parameter. If a port is
    # given, it is used to filter the couplings having this port as a source.
    #
    # @param port [Port, nil] the source port or nil
    # @yieldparam coupling [Coupling] the coupling that is yielded
    def each_output_coupling(port = nil, &block)
      each_coupling(@output_couplings, port, &block)
    end

    # The <i>Select</i> function as defined is the classic DEVS formalism.
    # Select one {Model} among all. By default returns the first. Override
    # if a different behavior is desired
    #
    # @param imminent_children [Array<Model>] the imminent children
    # @return [Model] the selected component
    # @example
    #   def select(imminent_children)
    #     imminent_children.sample
    #   end
    def select(imminent_children)
      imminent_children.first
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

        coupling = Coupling.new(input_port, child_port, :eic)
        @input_couplings[input_port] << coupling
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

        coupling = Coupling.new(child_port, output_port, :eoc)
        @output_couplings[child_port] << coupling
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

      coupling = Coupling.new(output_port, input_port, :ic)
      @internal_couplings[output_port] << coupling
    end

    # Deletes a coupling from {#couplings}.
    #
    # @param coupling [Coupling] the coupling to delete
    # @return [Coupling, nil] the deleted coupling or <tt>nil</tt> if not found
    def remove_coupling(coupling)
      case coupling.type
      when :ic  then @internal_couplings
      when :eoc then @output_couplings
      when :eic then @input_couplings
      end[coupling.port_source].delete(coupling)
    end

    # Deletes an internal coupling (IC) from {#internal_couplings}.
    #
    # @param coupling [Coupling] the coupling to delete
    # @return [Coupling, nil] the deleted coupling or <tt>nil</tt> if not found
    def remove_internal_coupling(coupling)
      @internal_couplings[coupling.port_source].delete(coupling)
    end

    # Deletes an internal coupling (EIC) from {#input_couplings}.
    #
    # @param coupling [Coupling] the coupling to delete
    # @return [Coupling, nil] the deleted coupling or <tt>nil</tt> if not found
    def remove_input_coupling(coupling)
      @input_couplings[coupling.port_source].delete(coupling)
    end

    # Deletes an internal coupling (EOC) from {#output_couplings}.
    #
    # @param coupling [Coupling] the coupling to delete
    # @return [Coupling, nil] the deleted coupling or <tt>nil</tt> if not found
    def remove_output_coupling(coupling)
      @output_couplings[coupling.port_source].delete(coupling)
    end

    # Calls <tt>block</tt> once for each coupling in passing that element as a
    # parameter. If a port is given, it is used to filter the couplings having
    # this port as a source.
    #
    # @param ary [Array] the array of couplings, defaults to {#couplings}
    # @param port [Port, nil] the source port or nil
    # @yieldparam coupling [Coupling] the coupling that is yielded
    def each_coupling(ary_or_hash = self.couplings, port = nil)
      if block_given?
        check = false
        ary = if port.nil? && ary_or_hash.kind_of?(Hash)
          ary_or_hash.values.flatten!
        elsif !port.nil? && ary_or_hash.kind_of?(Hash)
          ary_or_hash[port]
        else
          check = true unless port.nil?
          ary_or_hash
        end

        i = 0
        if check
          while i < ary.size
            coupling = ary[i]
            yield(coupling) if coupling.port_source == port
            i += 1
          end
        else
          while i < ary.size
            yield(ary[i])
            i += 1
          end
        end
      else
        to_enum(:each_coupling, ary_or_hash, port)
      end
    end

    def ensure_child(child)
      child = self[child] unless child.is_a?(Model)
      raise NoSuchChildError, "the child argument cannot be nil" if child.nil?
      child
    end
    private :ensure_child
  end
end
