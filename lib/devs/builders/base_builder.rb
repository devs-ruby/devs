module DEVS
  module BaseBuilder
    attr_reader :model, :processor

    def add_input_port(*args)
      @model.add_input_port(*args)
    end

    def add_output_port(*args)
      @model.add_output_port(*args)
    end
  end
end
