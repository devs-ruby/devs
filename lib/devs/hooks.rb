module DEVS
  module Hooks

    class << self
      def notifier
        @notifier ||= Notifier.new
      end

      # @see Notifier#subscribe
      def subscribe(hook, instance=nil, method=:notify, &block)
        self.notifier.subscribe(hook, instance, method, &block)
      end

      # @see Notifier#unsubscribe
      def unsubscribe(hook, instance=nil, method=:notify, &block)
        self.notifier.unsubscribe(hook, instance, method, &block)
      end

      # @see Notifier#notify
      def notify(hook, *args)
        self.notifier.notify(hook, *args)
      end
    end

    # The {Notifier} provides a mechanism for broadcasting hooks during a
    # simulation.
    #
    # Objects can register to hooks using the {#subscribe} method, either
    # using blocks, or by specifying a method (which defaults to {#notify})
    # which will handle the hook.
    class Notifier

      def listeners
        @listeners ||= Hash.new { |hash, key| hash[key] = [] }
      end
      private :listeners

      # Subscribes the given method or block to the specified hook
      #
      # @overload subscribe(hook, instance, method)
      #   Subscribes the receiver of the given method to the specified hook
      #   @param hook [Symbol] the hook to subscribe to
      #   @param instance [Object] the receiver of the method
      #   @param method [Symbol, String] the callback method, defaults to
      #     :notify
      # @overload subscribe(hook, &block)
      #   Subscribes the given block to the specified hook
      #   @param hook [Symbol] the hook to subscribe to
      def subscribe(hook, instance=nil, method = :notify, &block)
        listeners[hook] << if block
          Subscriber.new(&block)
        else
          Subscriber.new(instance, method)
        end
      end

      # Unsubscribes the specified entry from listening to the specified hook.
      def unsubscribe(hook, instance=nil, method = :notify)
        if instance.is_a?(Proc)
          @listeners.try { self[hook].reject! { |s|
            s.block == instance && s.receiver == instance.binding.receiver
          }} != nil
        else
          @listeners.try { self[hook].reject! { |s|
            s.receiver == instance && s.method == method
          }} != nil
        end
      end

      # @overload clear
      #   Removes all entries from the notifier.
      # @overload clear(hook)
      #   Removes all entries that previously registered to the specified *hook*
      #   from the notifier.
      #   @param hook [Symbol] the hook to clear
      def clear(hook = nil)
        if hook
          @listeners.try :delete, hook
        else
          @listeners.try :clear
        end
      end

      # @overload count_listeners
      #   Returns the total number of objects listening to hooks.
      #   @return [Integer] the number of listeners
      # @overload count_listeners(hook)
      #   Returns the number of objects listening for the specified *hook*.
      #   @param hook [Symbol] the hook to register
      #   @return [Integer] the number of listeners
      def count_listeners(hook = nil)
        if hook
          @listeners.try { self[hook].size }
        else
          @listeners.try { reduce(0) { |acc, tuple| acc + tuple[1].size }}
        end
      end

      # Publish the given hook, so that each registered object in the receiver
      # is notified.
      def notify(hook, *args)
        @listeners.try do
          self[hook].reject! do |s|
            begin
              s.notify(hook, *args)
              false
            rescue
              true # deletes the element in place since it raised
            end
          end
        end
      end
    end

    # @private
    class Subscriber
      attr_reader :receiver, :method, :block

      def initialize(instance=nil, method=nil, &blk)
        if blk
          @receiver = blk.binding.receiver
          @block = blk
        else
          @receiver = instance
          @method = method
        end
      end

      def notify(*args)
        if @block
          @block.call(*args)
        else
          @receiver.__send__(@method, *args)
        end
      end
    end
  end
end
