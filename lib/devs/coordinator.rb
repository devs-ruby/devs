module DEVS
  # This class represent a simulator associated with an {CoupledModel},
  # responsible to route events to proper children
  class Coordinator < Processor
    attr_reader :children

    # @!attribute [r] children
    #   This attribute returns a list of all its children, composed
    #   of {Simulator}s or/and {Coordinator}s.
    #   @return [Array<Processor, Coordinator>] Returns a list of all its child
    #     processors

    # Returns a new instance of {Coordinator}
    #
    # @param model [CoupledModel] the managed coupled model
    def initialize(model, scheduler:, namespace:, run_validations:)
      super(model)
      @children = []
      @namespace = namespace
      @run_validations = run_validations
      @scheduler = scheduler.new
    end

    def inspect
      "<#{self.class}: tn=#{@time_next}, tl=#{@time_last}, components=#{@children.count}>"
    end

    # Append a child to {#children} list, ensuring that the child now has
    # self as parent.
    #
    # @param child [Processor] the processor to append
    # @return [Processor] the newly added processor
    def <<(child)
      @children << child
      child.parent = self
      child
    end
    alias_method :add_child, :<<

    # Deletes the specified child from {#children} list
    #
    # @param child [Processor] the child to remove
    # @return [Processor] the deleted child
    def remove_child(child)
      @scheduler.delete(child)
      idx = @children.index { |x| child.equal?(x) }
      @children.delete_at(idx).parent = nil if idx
    end

    # Returns the minimum time next in all children
    #
    # @return [Numeric] the min time next
    def min_time_next
      tn = DEVS::INFINITY
      if (obj = @scheduler.peek)
        tn = obj.time_next
      end
      tn
    end

    # Returns the maximum time last in all children
    #
    # @return [Numeric] the max time last
    def max_time_last
      max = 0
      i = 0
      while i < @children.size
        tl = @children[i].time_last
        max = tl if tl > max
        i += 1
      end
      max
    end
  end
end
