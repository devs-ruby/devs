require "spec_helper"

class ObserverTestError < StandardError; end

class Foo < AtomicModel
  output_port :out
  attr_state :sigma, default: 0

  def internal_transition
    @sigma = INFINITY
  end

  def output
    post "value", :out
  end
end

class PortObserver
  attr_reader :calls, :port, :value

  def initialize(port)
    @calls = 0
    @port = nil
    @value = nil
    port.add_observer(self)
  end

  def update(observable, payload)
    @calls += 1
    @port = observable
    @value = payload
  end
end

class TransitionObserver
  attr_reader :init_calls, :int_calls, :ext_calls, :con_calls

  def initialize(model)
    @init_calls = 0
    @int_calls = 0
    @con_calls = 0
    @ext_calls = 0
    model.add_observer(self)
  end

  def update(model, transition)
    case transition
    when :init
      @init_calls += 1
    when :internal
      @int_calls += 1
    when :confluent
      @con_calls += 1
    when :external
      @ext_calls += 1
    end
  end
end

describe "Observered simulation scenario" do
  describe "port observer" do
    it "is notified when a value is dropped on an output port" do
      model = Foo.new(:foo)
      po = PortObserver.new(model.output_port(:out))
      sim = Simulation.new(model)
      sim.simulate

      po.calls.must_equal(1)
      po.port.must_be_same_as(model.output_port(:out))
    end
  end

  describe "transition observer" do
    it "is notified for each transition" do
      model = Foo.new(:foo)
      to = TransitionObserver.new(model)
      sim = Simulation.new(model)
      sim.simulate

      to.init_calls.must_equal 1
      to.int_calls.must_equal 1
    end
  end
end
