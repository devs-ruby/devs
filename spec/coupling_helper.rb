class MyCoupleable < Model
  include Coupleable

  def initialize(name)
    super(name)
    initialize_coupleable
  end

  def find_create(name, type)
    case type
    when :input
      find_or_create_input_port_if_necessary(name)
    when :output
      find_or_create_output_port_if_necessary(name)
    end
  end
end

class MyCoupler < Model
  include Coupleable
  include Container

  def initialize(name)
    super(name)
    initialize_coupleable
  end
end
