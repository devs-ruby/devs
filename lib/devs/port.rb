module DEVS

  # This class represents a port that belongs to a {Model} (the {#host}).
  class Port
    include Observable
    attr_reader :type, :name, :host

    # @!attribute [r] type
    #   @return [Symbol] Returns port's type, either <tt>:input</tt> or
    #     <tt>:output</tt>

    # @!attribute [r] name
    #   @return [Symbol] Returns the name identifying <tt>self</tt>

    # @!attribute [r] host
    #   @return [Model] Returns the model that owns <tt>self</tt>

    # Returns a new {Port} instance.
    #
    # @param host [Model] the owner of self
    # @param type [Symbol] the type of port, either <tt>:input</tt> or
    #   <tt>:output</tt>
    # @param name [String, Symbol] the name given to identify the port
    def initialize(host, type, name)
      type = type.downcase.to_sym unless type.nil?
      @type = type
      @name = name
      @host = host
    end

    # Add observer as an observer on this object so that it will receive
    # notifications.
    #
    # @see Observable#add_observer
    # @raise [UnobservablePortError] if the port is not an output port of an
    #   {AtomicModel}
    def add_observer(observer, func = :update)
      if @type == :input || @host.coupled?
        raise UnobservablePortError, "Only atomic models output ports are observable"
      end
      super(observer, func)
    end

    # Check if <tt>self</tt> is an input port
    #
    # @return [Boolean] <tt>true</tt> if <tt>self</tt> is an input port,
    #   <tt>false</tt> otherwise
    def input_port?
      @type == :input
    end
    alias_method :input?, :input_port?

    # Check if self is an output port
    #
    # @return [Boolean] <tt>true</tt> if <tt>self</tt> is an output port,
    #   <tt>false</tt> otherwise
    def output_port?
      @type == :output
    end
    alias_method :output?, :output_port?

    # @return [String]
    def to_s
      @name.to_s
    end

    def inspect
      "<#{self.class}: name=#{@name}, type=#{@type}, host=#{@host}>"
    end
  end
end
