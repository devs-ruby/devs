require "spec_helper"

class MyNotifiable
  attr_reader :calls

  def initialize
    @calls = 0
  end

  def notify(hook)
    @calls += 1
  end
end

class RaiseNotifiable < MyNotifiable
  def notify(hook)
    super(hook)
    raise "ohno"
  end
end


describe "Hooks" do
  describe "#subscribe" do
    it "accepts blocks" do
      notifier = Hooks::Notifier.new
      notifier.subscribe(:foo) {}
    end

    it "accepts any object" do
      notifier = Hooks::Notifier.new
      notifier.subscribe(:foo, MyNotifiable.new)
    end
  end

  describe "#count_listeners" do
    it "counts listeners for a given hook" do
      notifier = Hooks::Notifier.new
      notifier.subscribe(:foo) {}
      notifier.subscribe(:foo, MyNotifiable.new)
      notifier.count_listeners(:foo).must_equal(2)

      myproc = ->(s) {}
      mynotifiable = MyNotifiable.new

      notifier.subscribe(:bar, &myproc)
      notifier.subscribe(:bar, mynotifiable)
      notifier.count_listeners(:bar).must_equal(2)
      notifier.unsubscribe(:bar, myproc)
      notifier.count_listeners(:bar).must_equal(1)
      notifier.unsubscribe(:bar, mynotifiable)
      notifier.count_listeners(:bar).must_equal(0)
    end

    it "counts all listeners" do
      notifier = Hooks::Notifier.new
      notifier.subscribe(:foo) {}
      notifier.subscribe(:bar) {}
      notifier.count_listeners.must_equal(2)
    end
  end

  describe "#notify" do
    it "notifies right subscribers" do
      notifier = Hooks::Notifier.new
      notifiable = MyNotifiable.new
      notifier.subscribe(:foo, notifiable)
      calls = 0
      block = Proc.new { calls+=1 }
      notifier.subscribe(:bar, &block)

      notifier.notify(:foo)
      notifiable.calls.must_equal(1)
      calls.must_equal(0)

      notifier.notify(:bar)
      calls.must_equal(1)
      notifiable.calls.must_equal(1)
    end

    it "doens't fails when a subscriber raises" do
      notifier = Hooks::Notifier.new
      notifier.subscribe(:foo) { raise "ohno" }
      notifier.subscribe(:foo, RaiseNotifiable.new, :notify)
      notifier.notify(:foo)
    end

    it "automatically unsubscribes notifiables that raised" do
      notifier = Hooks::Notifier.new

      i = 0
      block = ->(s) { i += 1; raise "ohno" }
      notifier.subscribe(:foo, &block)

      notifiable = RaiseNotifiable.new
      notifier.subscribe(:foo, notifiable, :notify)

      notifier.count_listeners(:foo).must_equal(2)
      notifier.notify(:foo)
      notifier.count_listeners(:foo).must_equal(0)

      notifiable.calls.must_equal(1)
      i.must_equal(1)

      notifier.unsubscribe(:foo, notifiable).must_equal false
      notifier.unsubscribe(:foo, block).must_equal false
    end
  end

  describe "#clear" do
    it "clears all subscribers" do
      notifier = Hooks::Notifier.new
      notifiable = MyNotifiable.new
      notifier.subscribe(:foo, notifiable)
      calls = 0
      block = Proc.new { calls+=1 }
      notifier.subscribe(:bar, &block)

      notifier.clear

      notifier.notify(:foo)
      notifiable.calls.must_equal(0)
      notifier.notify(:bar)
      calls.must_equal(0)

      notifier.unsubscribe(:foo, notifiable).must_equal false
      notifier.unsubscribe(:bar, block).must_equal false
    end

    it "clears subscribers of given hook" do
      notifier = Hooks::Notifier.new
      notifiable = MyNotifiable.new
      notifier.subscribe(:foo, notifiable)

      j = 0
      block = Proc.new { j+=1 }
      notifier.subscribe(:bar, &block)

      notifier.clear(:foo)

      notifier.notify(:bar)
      notifier.notify(:foo)

      notifiable.calls.must_equal(0)
      j.must_equal(1)
      notifier.unsubscribe(:foo, notifiable).must_equal false
      notifier.unsubscribe(:bar, block).must_equal true
    end
  end

  describe "#unsubscribe" do
    it "is falsey when subscriber doesn't exist" do
      notifier = Hooks::Notifier.new
      notifiable = MyNotifiable.new
      notifiable2 = MyNotifiable.new
      notifier.subscribe(:bar, notifiable)

      notifier.unsubscribe(:foo, notifiable).must_equal false
      notifier.unsubscribe(:bar, notifiable2).must_equal false
    end

    it "is truthy when successful" do
      notifier = Hooks::Notifier.new
      notifiable = MyNotifiable.new
      notifiable2 = MyNotifiable.new
      calls = 0
      block = Proc.new { calls+=1 }

      notifier.subscribe(:foo, notifiable)
      lost_calls = 0
      notifier.subscribe(:foo) { lost_calls += 1 }
      notifier.subscribe(:bar, notifiable2)
      notifier.subscribe(:bar, &block)

      notifier.unsubscribe(:foo, notifiable).must_equal true
      notifier.notify(:foo)
      notifiable.calls.must_equal(0)
      lost_calls.must_equal(1)
      notifier.clear(:foo)
      notifier.notify(:foo)
      lost_calls.must_equal(1)

      notifier.unsubscribe(:bar, notifiable2).must_equal true
      notifier.unsubscribe(:bar, block).must_equal true
      notifier.notify(:bar)
      notifiable2.calls.must_equal(0)
      calls.must_equal(0)
    end
  end

end
