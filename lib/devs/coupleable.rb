module DEVS
  # The {Coupleable} mixin provides models with the ability to be coupled
  # through an input and output interface.
  module Coupleable
    extend ActiveSupport::Concern

    # @!group Syntax sugaring

    def initialize_coupleable
      self.class._input_ports.each { |name| add_port(:input, name) }
      self.class._output_ports.each { |name| add_port(:output, name) }
    end
    protected :initialize_coupleable

    module ClassMethods
      def input_port(*args)
        args.each { |arg| self._input_ports << arg.to_sym }
      end

      def output_port(*args)
        args.each { |arg| self._output_ports << arg.to_sym }
      end

      def _input_ports
        @_input_ports ||= self.superclass.singleton_class.method_defined?(:_input_ports) ? self.superclass._input_ports.dup : []
      end

      def _output_ports
        @_output_ports ||= self.superclass.singleton_class.method_defined?(:_output_ports) ? self.superclass._output_ports.dup : []
      end
    end

    # @!endgroup

    attr_reader :input_ports, :output_ports, :input_port_list,
            :output_port_list, :input_port_names, :output_port_names

    # @!attribute [r] input_ports
    #   This attribute represent the list of input {Port}s.
    #   @return [Array<Port>] Returns the array of input ports.

    # @!attribute [r] output_ports
    #   This attribute represent the list of output {Port}s.
    #   @return [Array<Port>] Returns the array of output ports.

    def input_ports
      @input_ports.values
    end

    def output_ports
      @output_ports.values
    end

    # Adds an input port to <tt>self</tt>.
    #
    # @param name [String, Symbol]
    # @return [Port, Array<Port>] the created port or the list of created ports
    def add_input_port(*names)
      add_port(:input, *names)
    end

    # Adds an output port to <tt>self</tt>.
    #
    # @param name [String, Symbol] the port name
    # @return [Port, Array<Port>] the created port or the list of created ports
    def add_output_port(*names)
      add_port(:output, *names)
    end

    def remove_input_port(name)
      @input_port_names = nil; @input_port_list = nil; # cache invalidation
      @input_ports.delete(name)
    end

    def remove_output_port(name)
      @output_port_names = nil; @output_port_list = nil; # cache invalidation
      @output_ports.delete(name)
    end

    # Returns the list of input ports' names
    #
    # @return [Array<String, Symbol>] the name list
    def input_ports_names
      @input_ports.keys
    end

    # Find the input {Port} identified by the given <tt>name</tt>
    #
    # @param name [String, Symbol] the port name
    # @return [Port] the matching port, nil otherwise
    def find_input_port_by_name(name)
      @input_ports[name]
    end

    # Returns the list of output ports' names
    #
    # @return [Array<String, Symbol>] the name list
    def output_ports_names
      @output_ports.keys
    end

    # Find the output {Port} identified by the given <tt>name</tt>
    #
    # @param name [String, Symbol] the port name
    # @return [Port] the matching port, nil otherwise
    def find_output_port_by_name(name)
      @output_ports[name]
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