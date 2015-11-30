module DEVS

  # This class represents a port that belongs to a {Model} (the {#host}).
  class Port
    attr_reader :type, :name, :host

    # @!attribute [r] type
    #   @return [Symbol] Returns port's type, either <tt>:input</tt> or
    #     <tt>:output</tt>

    # @!attribute [r] name
    #   @return [Symbol] Returns the name identifying <tt>self</tt>

    # @!attribute [r] host
    #   @return [Model] Returns the model that owns <tt>self</tt>

    # Represent the list of possible type of ports.
    #
    # 1. <tt>:input</tt> for an input port
    # 2. <tt>:output</tt> for an output port
    #
    # @return [Array<Symbol>] the port types
    def self.types
      [:input, :output]
    end

    # Returns a new {Port} instance.
    #
    # @param host [Model] the owner of self
    # @param type [Symbol] the type of port, either <tt>:input</tt> or
    #   <tt>:output</tt>
    # @param name [String, Symbol] the name given to identify the port
    # @raise [ArgumentError] if the specified type is unknown
    def initialize(host, type, name)
      type = type.downcase.to_sym unless type.nil?
      if type != :input && type != :output
        raise(ArgumentError, "type attribute must be either of #{Port.types}")
      end
      @type = type
      @name = name
      @host = host
    end

    # Check if <tt>self</tt> is an input port
    #
    # @return [Boolean] <tt>true</tt> if <tt>self</tt> is an input port,
    #   <tt>false</tt> otherwise
    def input_port?
      type == :input
    end
    alias_method :input?, :input_port?

    # Check if self is an output port
    #
    # @return [Boolean] <tt>true</tt> if <tt>self</tt> is an output port,
    #   <tt>false</tt> otherwise
    def output_port?
      type == :output
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
