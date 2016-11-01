require "spec_helper"

class FetchOutputTest < AtomicModel
  output_port "out"
  attr_state :calls, default: 0

  attr_reader :calls

  def output
    post 42, "out"
    @calls += 1
  end
end

describe "AtomicModel" do
  describe "post" do
    it "raises when dropping a value on an input port" do
      foo = AtomicModel.new("foo")
      fip = foo.add_input_port("in")

      assert_raises InvalidPortTypeError do
        foo.send :post, "test", fip
      end
    end

    it "raises when dropping a value on a port of another model" do
      foo = AtomicModel.new("foo")
      bar = AtomicModel.new("bar")
      bop = bar.add_output_port("out")

      assert_raises InvalidPortHostError do
        foo.send :post, "test", bop
      end
    end

    it "raises when port name doesn't exist" do
      foo = AtomicModel.new("foo")
      assert_raises NoSuchPortError do
        foo.send :post, "test", "out"
      end
    end
  end

  describe "fetch_output!" do
    it "calls #output" do
      m = FetchOutputTest.new("fetch_test")
      m._initialize_state
      m._fetch_output![m.output_port("out")].must_equal 42
      m.calls.must_equal 1
    end
  end

end
