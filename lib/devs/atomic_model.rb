module DEVS
  # This class represent a DEVS atomic model.
  class AtomicModel < Model
    include Coupleable
    include Behavior
    include Observable # NOTE : include as a concern in behavior ?
    include ActiveModel::Validations
    include ActiveModel::Serialization

    class << self
      attr_accessor :counter
    end
    @counter = 0

    # Returns a new instance of {AtomicModel}
    #
    # @param name [String, Symbol] the name of the model
    def initialize(name = nil)
      super(name)

      @input_ports = {}
      @output_ports = {}

      AtomicModel.counter += 1
      @name = :"#{self.class.name || 'AtomicModel'}#{AtomicModel.counter}" unless @name
      @bag = {}
      initialize_coupleable
    end

    # @!group ActiveModel serialization

    def attributes=(hash)
      @name = hash.delete(:name)
      self.initial_state = hash
    end

    def attributes
      hash = { name: @name }
      state_attrs = self.class._state_attributes
      state_attrs.each_key do |attr|
        # NOTE lot of string allocations
        hash[attr] = self.instance_variable_get(:"@#{attr}")
      end
      hash
    end

    # @!endgroup

    def processor
      @processor ||= DEVS.namespace::Simulator.new(self)
    end

    # Returns a boolean indicating if <tt>self</tt> is an atomic model
    #
    # @return [true]
    def atomic?
      true
    end

    def inspect
      "<#{self.class}: name=#{@name}, time=#{@time}, elapsed=#{@elapsed}>"
    end

    # Sends an output value to the specified output {Port}
    #
    # @param value [Object] the output value
    # @param port [Port, String, Symbol] the output port or its name
    # @return [Object] the posted output value
    # @raise [ArgumentError] if the given port is nil or doesn't exists
    # @raise [InvalidPortHostError] if the given port doesn't belong to this
    #   model
    # @raise [InvalidPortTypeError] if the given port isn't an output port
    def post(value, port)
      @bag[ensure_output_port(port)] = value
    end
    protected :post

    # Returns outgoing messages added by the DEVS lambda (λ) function for the
    # current state
    #
    # @note This method calls the DEVS lambda (λ) function
    # @api private
    # @return [Hash<Port,Object>]
    def _fetch_output!
      @bag.clear
      self.output
      @bag
    end

    # Finds and checks if the given port is an input port
    #
    # @api private
    # @param port [Port, String, Symbol] the port or its name
    # @return [Port] the matching port
    # @raise [ArgumentError] if the given port is nil or doesn't exists
    # @raise [InvalidPortHostError] if the given port doesn't belong to this
    #   model
    # @raise [InvalidPortTypeError] if the given port isn't an input port
    def ensure_input_port(port)
      raise ArgumentError, "port argument cannot be nil" if port.nil?
      unless port.kind_of?(Port)
        port = @input_ports[port]
        raise ArgumentError, "the given port doesn't exists" if port.nil?
      end
      unless port.host == self
        raise InvalidPortHostError, "The given port doesn't belong to this \
        model"
      end
      unless port.input?
        raise InvalidPortTypeError, "The given port isn't an input port"
      end
      port
    end
    protected :ensure_input_port

    # Finds and checks if the given port is an output port
    #
    # @api private
    # @param port [Port, String, Symbol] the port or its name
    # @return [Port] the matching port
    # @raise [ArgumentError] if the given port is nil or doesn't exists
    # @raise [InvalidPortHostError] if the given port doesn't belong to this
    #   model
    # @raise [InvalidPortTypeError] if the given port isn't an output port
    def ensure_output_port(port)
      raise ArgumentError, "port argument cannot be nil" if port.nil?
      unless port.kind_of?(Port)
        port = @output_ports[port]
        raise ArgumentError, "the given port doesn't exists" if port.nil?
      end
      unless port.host == self
        raise InvalidPortHostError, "The given port doesn't belong to this \
        model"
      end
      unless port.output?
        raise InvalidPortTypeError, "The given port isn't an output port"
      end
      port
    end
    protected :ensure_output_port
  end
end
