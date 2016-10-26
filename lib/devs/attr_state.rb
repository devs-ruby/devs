module DEVS
  # The {AttrState} mixin provides models with the ability to define a named
  # state attribute with a default value.
  module AttrState
    extend ActiveSupport::Concern

    def initial_state=(*_, **kargs)
      @_default_state = kargs
    end

    def _initialize_state
      state_attrs = self.class._state_attributes
      state_attrs.each_key do |state|
        value = self._default_state[state] || state_attrs[state]
        # NOTE lot of string allocations
        self.instance_variable_set(:"@#{state}", value.is_a?(Proc) ? value.call : value)
      end
    end

    protected
    def _default_state
      @_default_state ||= {}
    end

    module ClassMethods
      def attr_state(*args, default: nil, &block)
        args.each do |arg|
          state = arg.to_sym
          self._state_attributes[state] = block ? block : default
        end
      end

      def _state_attributes
        @_state_attributes ||= self.superclass.singleton_class.method_defined?(:_state_attributes) ? self.superclass._state_attributes.dup : {}
      end
    end
  end
end
