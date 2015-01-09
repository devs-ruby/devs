module DEVS
  module Hooks
    class << self
      def notifier
        @notifier ||= Fanout.new
      end

      def subscribe(hook, instance, method=nil)
        self.notifier.subscribe(hook, instance, method)
      end

      def publish(hook, *args)
        self.notifier.publish(hook, *args)
      end
    end

    class Fanout
      def initialize
        @listeners_for = Hash.new { |hash, key| hash[key] = [] }
      end

      def subscribe(hook, instance, method=nil)
        @listeners_for[hook] << Subscriber.new(instance, method || hook)
      end

      def publish(hook, *args)
        @listeners_for[hook].each { |s| s.publish(*args) }
      end
    end

    class Subscriber
      attr_reader :instance, :method

      def initialize(instance, method)
        @instance = instance
        @method = method
      end

      def publish(*args)
        @instance.__send__(@method, *args)
      end
    end
  end
end
