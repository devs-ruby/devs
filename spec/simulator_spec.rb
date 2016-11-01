require "spec_helper"

describe "Simulation" do

  describe "initialization" do
    it "accepts an atomic model" do
      Simulation.new(AtomicModel.new("am"))
    end

    it "is in waiting status" do
      sim = Simulation.new(AtomicModel.new("am"))
      sim.must_be :waiting?
      sim.wont_be :done?
      sim.wont_be :running?
      sim.status.must_equal :waiting
    end
  end



end
