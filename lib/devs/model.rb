module DEVS
  # @abstract Base model class
  class Model
    attr_accessor :name, :parent, :processor

    # @!attribute name
    #   This attribute represent the name of the model.
    #   @return [Symbol] Returns the name of the model.

    # @!attribute parent
    #   This attribute represent the associated {Processor}.
    #   @return [Processor] Returns the associated processor.

    # Returns a new {Model} instance.
    #
    # @param name [String, Symbol] the name of the model
    def initialize(name = nil)
      @name = name.to_sym unless name == nil
    end

    def name=(name)
      name = name.to_sym
      @parent.rename_child(name, @name) if @parent && @name
      @name = name
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

    # @return [String]
    def to_s
      name.to_s
    end
  end
end
