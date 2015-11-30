module DEVS
  class Processor
    include Comparable
    include Logging
    attr_reader :model, :time_next, :time_last
    attr_accessor :parent

    # @!attribute [rw] parent
    #   @return [Coordinator] Returns the parent {Coordinator}

    # @!attribute [r] model
    #   @return [Model] Returns the model associated with <tt>self</tt>

    # @!attribute [r] time_next
    #   @return [Numeric] Returns the next simulation time at which the
    #     associated {Model} should be activated

    # @!attribute [r] time_last
    #   @return [Numeric] Returns the last simulation time at which the
    #     associated {Model} was activated

    # Returns a new {Processor} instance.
    #
    # @param model [Model] the model associated with this processor
    def initialize(model)
      @model = model
      @model.processor = self
      @time_next = 0
      @time_last = 0
    end

    # The comparison operator. Compares two processors given their #time_next
    #
    # @param other [Processor]
    # @return [Integer]
    def <=>(other)
      other.time_next <=> @time_next
    end

    def ==(other)
      self.equal?(other)
    end

    def inspect
      "<#{self.class}: tn=#{@time_next}, tl=#{@time_last}>"
    end
  end
end
