module DEVS
  # @abstract Base model class for {AtomicModel} and {CoupledModel} classes
  class Model
    attr_accessor :name, :processor
    attr_reader :input_ports, :output_ports, :input_ports_list,
                :output_ports_list, :input_ports_names, :output_ports_names

    # @!attribute name
    #   This attribute represent the name of the model.
    #   @return [Symbol] Returns the name of the model.

    # @!attribute processor
    #   This attribute represent the associated {Processor}.
    #   @return [Processor] Returns the associated processor.

    # @!attribute [r] input_ports
    #   This attribute represent the dictionary of input {Port}s, indexed by
    #     their names.
    #   @return [Hash<Symbol,Port>] Returns the hash of input ports indexed by
    #     their names.

    # @!attribute [r] output_ports
    #   This attribute represent the list of output {Port}s, indexed by their
    #     names.
    #   @return [Hash<Symbol,Port] Returns the hash of output ports indexed by
    #     their names.

    # @!attribute [r] input_port_list
    #   This attribute represent the list of input {Port}s.
    #   @return [Array<Port>] Returns the array of input ports.

    # @!attribute [r] output_port_list
    #   This attribute represent the list of output {Port}s.
    #   @return [Array<Port>] Returns the array of output ports.

    # @!attribute [r] input_port_names
    #   This attribute represent the list of names of the input {Port}s.
    #   @return [Array<Symbol>] Returns the array of input ports names.

    # @!attribute [r] output_port_names
    #   This attribute represent the list of names of the output {Port}s.
    #   @return [Array<Symbol>] Returns the array of output ports names.

    # Returns a new {Model} instance.
    #
    # @param name [String, Symbol] the name of the model
    def initialize(name = nil)
      @name = name.to_sym unless name == nil
      @input_ports = {}
      @output_ports = {}
    end

    # Returns a boolean indicating if <tt>self</tt> is an atomic model
    #
    # @return [false]
    def atomic?
      false
    end

    # Returns a boolean indicating if <tt>self</tt> is an atomic model
    #
    # @return [false]
    def coupled?
      false
    end

    def inspect
      "<#{self.class}: name=#{@name}>"
    end

    # Adds an input port to <tt>self</tt>.
    #
    # @param name [String, Symbol]
    # @return [Port, Array<Port>] the created port or the list of created ports
    def add_input_port(*names)
      @input_port_names = nil; @input_port_list = nil; # cache invalidation
      add_port(:input, *names)
    end

    # Adds an output port to <tt>self</tt>.
    #
    # @param name [String, Symbol] the port name
    # @return [Port, Array<Port>] the created port or the list of created ports
    def add_output_port(*names)
      @output_port_names = nil; @output_port_list = nil; # cache invalidation
      add_port(:output, *names)
    end

    # Returns the list of input ports' names
    #
    # @return [Array<String, Symbol>] the name list
    def input_port_names
      @input_port_names ||= @input_ports.keys
    end

    # Returns the list of output ports' names
    #
    # @return [Array<String, Symbol>] the name list
    def output_port_names
      @output_port_names ||= @output_ports.keys
    end

    def input_port_list
      @input_port_list ||= @input_ports.values
    end

    def output_port_list
      @output_port_list ||= @output_ports.values
    end

    # Find the input {Port} identified by the given <tt>name</tt>
    #
    # @param name [String, Symbol] the port name
    # @return [Port] the matching port, nil otherwise
    def find_input_port_by_name(name)
      @input_ports[name]
    end

    # Find the output {Port} identified by the given <tt>name</tt>
    #
    # @param name [String, Symbol] the port name
    # @return [Port] the matching port, nil otherwise
    def find_output_port_by_name(name)
      @output_ports[name]
    end

    # @return [String]
    def to_s
      name.to_s
    end

    protected

    # Find or create an input port if necessary. If the given argument is nil,
    # an input port is created with a default name. Otherwise, an attempt to
    # find the matching port is made. If the given port doesn't exists, it is
    # created with the given name.
    #
    # @param port [String, Symbol] the input port name
    # @return [Port] the matching port or the newly created port
    def find_or_create_input_port_if_necessary(port)
      find_or_create_port_if_necessary(:input, port)
    end

    # Find or create an output port if necessary. If the given argument is nil,
    # an output port is created with a default name. Otherwise, an attempt to
    # find the matching port is made. If the given port doesn't exists, it is
    # created with the given name.
    #
    # @param port [String, Symbol] the output port name
    # @return [Port] the matching port or the newly created port
    def find_or_create_output_port_if_necessary(port)
      find_or_create_port_if_necessary(:output, port)
    end

    private

    def find_or_create_port_if_necessary(type, port)
      unless port.kind_of?(Port)
        name = port
        port = case type
        when :output then @output_ports[name]
        when :input then @input_ports[name]
        end

        if port.nil?
          port = add_port(type, name)
          DEVS.logger.warn("specified #{type} port #{name} doesn't exist for #{self}. creating it") if DEVS.logger
        end
      end
      port
    end

    def add_port(type, *names)
      ports = case type
      when :input then @input_ports
      when :output then @output_ports
      end

      new_ports = []
      i = 0
      while i < names.size
        n = names[i].to_sym
        if ports.has_key?(n)
          DEVS.logger.warn(
            "specified #{type} port #{n} already exists for #{self}. skipping..."
          ) if DEVS.logger
        else
          p = Port.new(self, type, n)
          ports[n] = p
          new_ports << p
        end
        i += 1
      end

      new_ports.size == 1 ? new_ports.first : new_ports
    end
  end
end
