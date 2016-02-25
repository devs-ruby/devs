module DEVS
  module Hooks
    class << self
      def notifier
        @notifier ||= Fanout.new
      end

      # @see Fanout#subscribe
      def subscribe(hook, instance=nil, method=nil, &block)
        self.notifier.subscribe(hook, instance, method, &block)
      end

      def unsubscribe(hook, instance=nil, method=nil, &block)
        self.notifier.unsubscribe(hook, instance, method, &block)
      end

      def publish(hook, *args)
        self.notifier.publish(hook, *args)
      end
    end

    class Fanout
      def initialize
        @listeners_for = Hash.new { |hash, key| hash[key] = [] }
      end

      # Subscribes the given method or block to the specified hook
      #
      # @overload subscribe(hook, instance, method)
      #   Subscribes the receiver of the given method to the specified hook
      #   @param hook [Symbol] the hook to subscribe to
      #   @param instance [Object] the receiver of the method
      #   @param method [Symbol, String] the callback method
      # @overload subscribe(hook, &block)
      #   Subscribes the given block to the specified hook
      #   @param hook [Symbol] the hook to subscribe to
      def subscribe(hook, instance=nil, method=nil, &block)
        @listeners_for[hook] << if block
          Subscriber.new(&block)
        else
          Subscriber.new(instance, method || hook)
        end
      end

      def unsubscribe(hook, instance=nil, method=nil, &block)
        if block
          @listeners_for[hook].delete_if { |s| s.block == block }
        elsif method
          @listeners_for[hook].delete_if do |s|
            s.receiver == instance && s.method == method
          end
        else
          @listeners_for[hook].delete_if { |s| s.receiver == instance }
        end
      end

      def publish(hook, *args)
        @listeners_for[hook].each { |s| s.publish(*args) }
      end
    end

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

      def publish(*args)
        if @block
          @block.call(*args)
        else
          @receiver.__send__(@method, *args)
        end
      end
    end
  end
end
