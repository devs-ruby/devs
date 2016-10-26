module DEVS

  # NOTE: singleton models cannot be serialized

  class AtomicBuilder
    include BaseBuilder

    def initialize(parent, klass, name:, with_args: {}, &block)
      @model = if klass.nil? || !klass.respond_to?(:new)
        AtomicModel.new(name)
      else
        m = klass.new(name)
        m.initial_state = with_args
        m
      end
      parent.model << @model
      instance_eval(&block) if block
    end

    def init(&block)
      @model.instance_eval(&block) if block
    end

    # DEVS functions
    def external_transition(&block)
      @model.define_singleton_method(:external_transition, &block) if block
    end
    alias_method :when_input_received, :external_transition

    def internal_transition(&block)
      @model.define_singleton_method(:internal_transition, &block) if block
    end
    alias_method :after_output, :internal_transition

    def confluent_transition(&block)
      @model.define_singleton_method(:confluent_transition, &block) if block
    end
    alias_method :if_transition_collides, :confluent_transition

    def reverse_confluent_transition!
      @model.define_singleton_method(:confluent_transition) do |messages|
        external_transition(messages)
        internal_transition
      end
    end

    def time_advance(&block)
      @model.define_singleton_method(:time_advance, &block) if block
    end

    def output(&block)
      @model.define_singleton_method(:output, &block) if block
    end

    # Hooks
    def post_simulation_hook(&block)
      if block
        @model.define_singleton_method(:post_simulation_hook, &block)
        Hooks.notifier.subscribe(:post_simulation_hook, @model, :post_simulation_hook)
      end
    end
  end
end
