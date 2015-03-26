require 'test_helper'

require 'minitest/autorun'
require 'minitest/mock'

require 'devs'

class TestModel < MiniTest::Test
  def setup
    @model = Model.new
  end

  def test_find_or_create_port
    pin1 = @model.add_input_port(:in)
    pout1 = @model.add_output_port(:out)

    pin2 = @model.send(:find_or_create_input_port_if_necessary, :in)
    pout2 = @model.send(:find_or_create_output_port_if_necessary, :out)
    assert_same pin1, pin2
    assert_same pout1, pout2

    pin1 = @model.send(:find_or_create_input_port_if_necessary, :newin)
    pout1 = @model.send(:find_or_create_output_port_if_necessary, :newout)

    assert_same @model.find_input_port_by_name(:newin), pin1
    assert_same @model.find_output_port_by_name(:newout), pout1
  end

  def test_neither_atomic_or_coupled
    refute @model.atomic?
    refute @model.coupled?
  end

  def test_add_ports
    inputs = [:in_1, :in_2]
    out = :out

    i_ports = @model.add_input_port(*inputs)
    o_port = @model.add_output_port(out)

    assert_kind_of(Array, i_ports)
    assert_kind_of(Port, o_port)
    assert_equal(2, i_ports.size)

    assert_equal(:in_1, i_ports.first.name)
    assert_equal(:in_2, i_ports.last.name)
    assert_equal(:out, o_port.name)

    assert_equal(:input, i_ports.sample.type)
    assert_equal(:output, o_port.type)

    assert_equal(@model, i_ports.sample.host)
    assert_equal(@model, o_port.host)
  end


end
