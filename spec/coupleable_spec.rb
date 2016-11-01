require "spec_helper"
require "coupling_helper"

describe "Coupleable" do
  describe "port creation" do
    it "adds ports" do
      c = MyCoupleable.new("a")
      ip = Port.new(c, :input, "input")
      op = Port.new(c, :output, :output)
      c.add_port ip
      c.add_port op

      c.input_port("input").must_be_same_as ip
      c.output_port(:output).must_be_same_as op
    end

    it "adds port by name" do
      c = MyCoupleable.new("a")
      ip = c.add_input_port("in")
      ip.must_be_instance_of(Port)
      op = c.add_output_port("out")
      op.must_be_instance_of(Port)

      c.input_port("in").must_be_same_as ip
      c.output_port("out").must_be_same_as op
    end
  end

  describe "port removal" do
    it "removes ports" do
      c = MyCoupleable.new("a")
      ip = Port.new(c, :input, "input")
      op = Port.new(c, :output, :output)
      c.add_port(ip)
      c.add_port(op)

      c.remove_port(ip).must_be_same_as ip
      c.remove_port(op).must_be_same_as op
    end

    it "removes ports by name" do
      c = MyCoupleable.new("a")
      ip = c.add_input_port("in")
      op = c.add_output_port("out")
      c.remove_input_port("in").must_be_same_as ip
      c.remove_output_port("out").must_be_same_as op
    end

    it "gets nilable" do
      MyCoupleable.new("a").remove_input_port("hello").must_be_nil
      MyCoupleable.new("a").remove_output_port("hello").must_be_nil
    end
  end

  describe "port retrieval" do
    it "raises on unknown port" do
      assert_raises(NoSuchPortError) do
        MyCoupleable.new("a").input_port("hello")
      end
      assert_raises(NoSuchPortError) do
        MyCoupleable.new("a").output_port("hello")
      end
    end

    it "gets nilable when given port doesn't exist" do
      MyCoupleable.new("a").input_port?("hello").must_be_nil
      MyCoupleable.new("a").output_port?("hello").must_be_nil
    end

    it "creates specified port if it doesn't exist" do
      c = MyCoupleable.new("a")
      ip = c.find_create("in", :input)
      op = c.find_create("out", :output)

      ip.must_be_instance_of(Port)
      op.must_be_instance_of(Port)
      ip.name.must_equal "in"
      op.name.must_equal "out"

      ip2 = c.add_input_port("in2")
      op2 = c.add_output_port("out2")

      c.find_create("in2", :input).must_be_same_as ip2
      c.find_create("out2", :output).must_be_same_as op2
    end
  end

  it "returns the list of port names" do
    c = MyCoupleable.new("a")
    c.add_input_port("in")
    c.add_input_port("in2")
    c.add_input_port("in3")

    c.add_output_port("out")
    c.add_output_port("out1")

    c.input_port_names.must_equal ["in", "in2", "in3"]
    c.output_port_names.must_equal ["out", "out1"]
  end

  it "returns the list of ports" do
    c = MyCoupleable.new("a")
    in1 = c.add_input_port("in")
    in2 = c.add_input_port("in2")
    in3 = c.add_input_port("in3")

    out1 = c.add_output_port("out")
    out2 = c.add_output_port("out1")

    c.input_port_list.must_equal [in1, in2, in3]
    c.output_port_list.must_equal [out1, out2]
  end

end
