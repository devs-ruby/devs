module DEVS
  # The {Coupleable} mixin provides models with the ability to be coupled
  # through an input and output interface.
  module Coupleable
    extend ActiveSupport::Concern

    # @!group Syntax sugaring

    def initialize_coupleable
      self.class._input_ports.each { |name| create_port(:input, name) }
      self.class._output_ports.each { |name| create_port(:output, name) }
    end
    protected :initialize_coupleable

    module ClassMethods
      def input_port(name)
        self._input_ports << name
      end

      def input_ports(*args)
        args.each { |arg| self._input_ports << arg }
      end

      def output_port(name)
        self._output_ports << name
      end

      def output_ports(*args)
        args.each { |arg| self._output_ports << arg }
      end

      def _input_ports
        @_input_ports ||= self.superclass.singleton_class.method_defined?(:_input_ports) ? self.superclass._input_ports.dup : []
      end

      def _output_ports
        @_output_ports ||= self.superclass.singleton_class.method_defined?(:_output_ports) ? self.superclass._output_ports.dup : []
      end
    end

    # @!endgroup

    # Add given port to *self*
    def add_port(port)
      raise InvalidPortHostError if port.host != self
      case port.type
      when :input
        input_ports[port.name] = port
      when :output
        output_ports[port.name] = port
      end
    end

    # Adds given input ports to <tt>self</tt>.
    #
    # @param name [String, Symbol] the port name
    # @return [Array<Port>] the created port or the list of created ports
    def add_input_ports(*names)
      create_port(:input, *names)
    end
    alias_method :add_input_port, :add_input_ports

    # Adds given output ports to <tt>self</tt>.
    #
    # @param name [String, Symbol] the port name
    # @return [Port, Array<Port>] the created port or the list of created ports
    def add_output_ports(*names)
      create_port(:output, *names)
    end
    alias_method :add_output_port, :add_output_ports

    # Removes given port from <tt>self</tt>
    def remove_port(port)
      case port.type
      when :input
        input_ports.delete(port.name)
      when :output
        output_ports.delete(port.name)
      end
    end

    # Removes given input port by its name.
    def remove_input_port(name)
      input_ports.delete(name)
    end

    # Removes given output port by its name.
    def remove_output_port(name)
      output_ports.delete(name)
    end

    # Returns the list of input ports' names
    #
    # @return [Array<String, Symbol>] the name list
    def input_port_names
      input_ports.keys
    end

    # Returns the list of output ports' names
    #
    # @return [Array<String, Symbol>] the name list
    def output_port_names
      output_ports.keys
    end

    # Returns the list of input ports
    def input_port_list
      input_ports.values
    end

    # Returns the list of output ports
    def output_port_list
      output_ports.values
    end

    # Find the input port identified by the given *name*.
    def input_port?(name)
      input_ports[name]
    end

    # Find the input port identified by the given *name*.
    def input_port(name)
      raise NoSuchPortError.new("input port \"#{name}\" not found") unless input_ports.has_key?(name)
      input_ports[name]
    end

    # Find the output port identified by the given *name*
    def output_port?(name)
      output_ports[name]
    end

    # Find the output port identified by the given *name*
    def output_port(name)
      raise NoSuchPortError.new("output port \"#{name}\" not found") unless output_ports.has_key?(name)
      output_ports[name]
    end

    protected

    def input_ports
      @input_ports ||= {}
    end

    def output_ports
      @output_ports ||= {}
    end

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
        when :output then output_ports[name]
        when :input then input_ports[name]
        end

        if port.nil?
          port = create_port(type, name)
          DEVS.logger.warn("specified #{type} port #{name} doesn't exist for #{self}. creating it") if DEVS.logger
        end
      end
      port
    end

    def create_port(type, *names)
      ports = case type
      when :input then input_ports
      when :output then output_ports
      end

      new_ports = []
      i = 0
      while i < names.size
        n = names[i]
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
