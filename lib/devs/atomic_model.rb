module DEVS
  # This class represent a DEVS atomic model.
  class AtomicModel < Model
    attr_accessor :elapsed, :time, :sigma, :next_activation

    # @!attribute sigma
    #   Sigma is a convenient variable introduced to simplify modeling phase
    #   and represent the next activation time (see {#time_advance})
    #   @return [Numeric] Returns the sigma (σ) value

    # @!attribute elapsed
    #   This attribute is updated along simulation. It represents the elapsed
    #   time since the last transition.
    #   @return [Numeric] Returns the elapsed time since the last transition

    # @!attribute time
    #   This attribute is updated along with simulation clock and
    #   represent the last simulation time at which this model
    #   was activated. Its default assigned value is {INFINITY}.
    #   @return [Numeric] Returns the last activation time

    # syntax sugaring
    class << self
      # @!group Class level DEVS functions

      # Defines the external transition function (δext) using the given block
      # as body.
      #
      # @see #external_transition
      # @example
      #   external_transition do |messages|
      #     messages.each { |msg| }
      #       puts "#{msg.port} => #{msg.payload}"
      #     end
      #
      #     self.sigma = 0
      #   end
      # @return [void]
      def external_transition(&block)
        define_method(:external_transition, &block) if block
      end

      # Defines the internal transition function (δint) using the given block
      # as body.
      #
      # @see #internal_transition
      # @example
      #   internal_transition { self.sigma = DEVS::INFINITY }
      # @return [void]
      def internal_transition(&block)
        define_method(:internal_transition, &block) if block
      end

      # Defines the confluent transition function (δcon) using the given block
      # as body.
      #
      # @see #confluent_transition
      # @example
      #   confluent_transition do |messages|
      #     internal_transition
      #     external_transition(messages)
      #   end
      # @return [void]
      def confluent_transition(&block)
        define_method(:confluent_transition, &block) if block
      end

      # Defines the opposite behavior of the default confluent transition
      # function (δcon).
      #
      # @see #confluent_transition
      # @example
      #   class MyModel < AtomicModel
      #     reverse_confluent_transition!
      #     # ...
      #   end
      def reverse_confluent_transition!
        define_method(:confluent_transition) do |messages|
          external_transition(messages)
          internal_transition
        end
      end

      # Defines the time advance function (ta) using the given block as body.
      #
      # @see #time_advance
      # @example
      #   time_advance { self.sigma }
      # @return [void]
      def time_advance(&block)
        define_method(:time_advance, &block) if block
      end

      # Defines the output function (λ) using the given block as body.
      #
      # @see #output
      # @example
      #   output do
      #     post(@some_value, output_ports.first)
      #   end
      # @return [void]
      def output(&block)
        define_method(:output, &block) if block
      end

      # @!endgroup

      attr_accessor :counter
    end

    @counter = 0

    # Returns a new instance of {AtomicModel}
    #
    # @param name [String, Symbol] the name of the model
    def initialize(name = nil)
      super(name)
      AtomicModel.counter += 1
      @name = "#{self.class.name || 'Anonymous'}#{AtomicModel.counter}" unless @name

      @elapsed = 0.0
      @sigma = INFINITY
      @time = 0
      @bag = []
    end

    def next_activation
      @sigma
    end

    def next_activation=(value)
      @sigma = value
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
      ensure_output_port(port).drop_off(value)
    end
    protected :post

    # Returns outgoing messages added by the DEVS lambda (λ) function for the
    # current state
    #
    # @note This method calls the DEVS lambda (λ) function
    # @api private
    # @return [Array<Message>]
    def fetch_output!
      self.output
      @bag.clear

      @output_ports.each_value do |port|
        value = port.pick_up
        @bag << Message.new(value, port) unless value.nil?
      end

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

    # @!group DEVS functions

    # The external transition function (δext), called each time a
    # message is sent to one of all {#input_ports}
    #
    # @abstract Override this method to implement the appropriate behavior of
    #   your model or define it with {AtomicModel.external_transition}
    # @see AtomicModel.external_transition
    # @param messages [Array<Message>] the frozen messages that wraps the payload
    #   generated by other {Model}s and the output {Port}.
    # @example
    #   def external_transition(messages)
    #     messages.each { |msg|
    #       puts "#{msg.port} => #{msg.payload}"
    #     }
    #
    #     self.sigma = 0
    #   end
    # @return [void]
    def external_transition(messages); end

    # Internal transition function (δint), called when the model should be
    # activated, e.g when {#elapsed} reaches {#time_advance}
    #
    # @abstract Override this method to implement the appropriate behavior of
    #   your model or define it with {AtomicModel.internal_transition}
    # @see AtomicModel.internal_transition
    # @example
    #   def internal_transition; self.sigma = DEVS::INFINITY; end
    # @return [void]
    def internal_transition; end

    # Time advance function (ta), called after each transition to give a
    # chance to <tt>self</tt> to be active. By default returns {#sigma}
    #
    # @note Override this method to implement the appropriate behavior of
    #   your model or define it with {AtomicModel.time_advance}
    # @see AtomicModel.time_advance
    # @example
    #   def time_advance; self.sigma; end
    # @return [Numeric] the time to wait before the model will be activated
    def time_advance
      @sigma
    end

    # This is the default definition of the confluent transition. Here the
    # internal transition is allowed to occur and this is followed by the
    # effect of the external transition on the resulting state.
    #
    # Override this method to obtain a different behavior. For example, the
    # opposite order of effects (external transition before internal
    # transition). Of course you can override without reference to the other
    # transitions.
    #
    # @see AtomicModel.reverse_confluent_transition!
    # @todo see elapsed time reset
    def confluent_transition(messages)
      internal_transition
      external_transition(messages) unless messages.nil? || messages.empty?
    end

    # The output function (λ)
    #
    # @abstract Override this method to implement the appropriate behavior of
    #   your model or define it with {AtomicModel.output}
    # @see AtomicModel.output
    # @example
    #   def output
    #     post(@some_value, output_ports.first)
    #   end
    # @return [void]
    def output; end

    # @!endgroup
  end
end
