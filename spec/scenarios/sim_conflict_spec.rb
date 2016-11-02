require "spec_helper"

class ConflictTestError < StandardError; end

class G < AtomicModel
  output_port :out
  attr_state :sigma, default: 1

  attr_reader :output_calls, :int_calls
  attr_state :output_calls, :int_calls, default: 0

  def output
    @output_calls += 1
    post "value", :out
  end

  def internal_transition
    @int_calls += 1
    @sigma = INFINITY
  end
end

module EventCollisionCDEVS
  class R < AtomicModel
    attr_state :sigma, default: 1
    input_port :in

    attr_state :ext_calls, :int_calls, :out_calls, default: 0
    attr_reader :ext_calls, :int_calls, :out_calls

    def external_transition(bag)
      @ext_calls += 1

      raise ConflictTestError.new("elapsed time should eq 1") unless @elapsed == 1
      raise ConflictTestError.new("bag should contain (:in, [\"value\"])") unless bag[input_port(:in)] == ["value"]

      @sigma -= @elapsed
    end

    def internal_transition
      @int_calls += 1
      @sigma = INFINITY
    end

    def confluent_transition(bag)
      raise ConflictTestError.new
    end

    def output
      @out_calls += 1
    end
  end

  class RLoseInternalEvent < R
    def external_transition(bag)
      super(bag)
      @sigma = INFINITY
    end
  end

  class RDelayInternalEvent < R
    def external_transition(bag)
      super(bag)
      @sigma = 1
    end
  end

  class Coupled < CoupledModel
    attr_reader :g, :r
    attr_reader :select_calls

    def initialize(r_klass = R)
      super("test_pdevs_delta_con")
      @select_calls = 0

      @r = r_klass.new :R
      @g = G.new :G

      self << @r << @g

      attach(:out, to: :in, between: :G, and: :R)
    end

    def select(imm)
      @select_calls += 1
      imm.sort_by(&:name).first
    end
  end
end

module EventCollisionPDEVS
  class R < AtomicModel
    attr_state :sigma, default: 1
    input_port :in

    attr_state :con_calls, :out_calls, default: 0
    attr_reader :con_calls, :out_calls

    def external_transition(bag)
      raise ConflictTestError.new
    end

    def confluent_transition(bag)
      @con_calls += 1

      # TODO use observer ?
      raise ConflictTestError.new("elapsed time should eq 0") unless @elapsed == 0
      raise ConflictTestError.new("bag should contain (:in, [\"value\"])") unless bag[input_port(:in)] == ["value"]

      @sigma = INFINITY
    end

    def internal_transition
      raise ConflictTestError.new
    end

    def output
      @out_calls += 1
    end
  end

  class Coupled < CoupledModel
    attr_reader :g, :r

    def initialize
      super("test_pdevs_delta_con")

      @r = R.new :R
      @g = G.new :G

      self << @r << @g

      attach(:out, to: :in, between: :G, and: :R)
    end
  end
end

describe "Event collision" do
  describe "PDEVS simulation" do
    describe "∂con is called when a conflict occur" do
      it "does for full hierarchy" do
        m = EventCollisionPDEVS::Coupled.new
        sim = Simulation.new(m, maintain_hierarchy: true, formalism: :pdevs)
        sim.simulate

        m.r.con_calls.must_equal(1)
        m.r.out_calls.must_equal(1)
        m.g.int_calls.must_equal(1)
        m.g.output_calls.must_equal(1)
      end

      it "does with flattening" do
        m = EventCollisionPDEVS::Coupled.new
        sim = Simulation.new(m, maintain_hierarchy: false, formalism: :pdevs)
        sim.simulate

        m.r.con_calls.must_equal(1)
        m.r.out_calls.must_equal(1)
        m.g.int_calls.must_equal(1)
        m.g.output_calls.must_equal(1)
      end
    end
  end

  describe "CDEVS simulation" do
    describe "when a conflict occurs" do
      describe "∂int and ∂ext calls are serialized via the select function" do
        it "does for full hierarchy" do
          m = EventCollisionCDEVS::Coupled.new
          sim = Simulation.new(m, maintain_hierarchy: true, formalism: :cdevs)
          sim.simulate

          m.select_calls.must_equal 1

          m.g.int_calls.must_equal 1
          m.g.output_calls.must_equal 1

          m.r.out_calls.must_equal 1
          m.r.int_calls.must_equal 1
          m.r.ext_calls.must_equal 1
        end

        it "does with flattening" do
          m = EventCollisionCDEVS::Coupled.new
          sim = Simulation.new(m, maintain_hierarchy: false, formalism: :cdevs)
          sim.simulate

          m.select_calls.must_equal 1

          m.g.int_calls.must_equal 1
          m.g.output_calls.must_equal 1

          m.r.out_calls.must_equal 1
          m.r.int_calls.must_equal 1
          m.r.ext_calls.must_equal 1
        end
      end
    end

    describe "an external event might" do
      it "delay an internal event" do
        m = EventCollisionCDEVS::Coupled.new(EventCollisionCDEVS::RDelayInternalEvent)
        sim = Simulation.new(m, formalism: :cdevs)
        sim.simulate

        m.select_calls.must_equal 1
      end

      it "cancel an internal event" do
        m = EventCollisionCDEVS::Coupled.new(EventCollisionCDEVS::RLoseInternalEvent)
        sim = Simulation.new(m, formalism: :cdevs)
        sim.simulate

        m.select_calls.must_equal 1
      end
    end
  end
end
