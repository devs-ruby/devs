module DEVS
  # This class represent a DEVS coupled model.
  class CoupledModel < Model
    include Coupleable
    include Container

    class << self
      def processor_for(namespace)
        namespace::Coordinator
      end

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
      initialize_coupleable
    end

    # Returns a boolean indicating if <tt>self</tt> is a coupled model
    #
    # @return [true]
    def coupled?
      true
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
  end
end
