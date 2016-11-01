require "spec_helper"

class GenTestError < StandardError; end

class TestGen < AtomicModel

  attr_reader :output_calls, :internal_calls
  attr_state :output_calls, :internal_calls, default: 0

  def output
    @output_calls += 1
  end

  def time_advance
    1
  end

  def internal_transition
    @internal_calls += 1

    raise GenTestError.new unless @elapsed == 0
    raise GenTestError.new unless @time == @internal_calls-1
  end
end

describe "Generator Model" do
  describe "PDEVS simulation" do
    it "calls ∂int and lambda" do
      gen = TestGen.new(:testgen)
      sim = Simulation.new(gen, duration: 10, formalism: :pdevs)

      sim.each_with_index { |e, i|
        gen.output_calls.must_equal(i+1)
        gen.internal_calls.must_equal(i+1)
        gen.time.must_equal(i+1)
      }

      gen.output_calls.must_equal(9)
      gen.internal_calls.must_equal(9)
      gen.time.must_equal(9)
    end
  end

  describe "CDEVS simulation" do
    it "calls ∂int and lambda" do
      gen = TestGen.new(:testgen)
      sim = Simulation.new(gen, duration: 10, formalism: :cdevs)

      sim.each_with_index { |e, i|
        gen.output_calls.must_equal(i+1)
        gen.internal_calls.must_equal(i+1)
        gen.time.must_equal(i+1)
      }

      gen.output_calls.must_equal(9)
      gen.internal_calls.must_equal(9)
      gen.time.must_equal(9)
    end
  end
end
