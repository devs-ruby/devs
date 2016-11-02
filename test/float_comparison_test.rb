require "test_helper"

class TestFloatComparison < MiniTest::Test
  def test_large_numbers
    assert 1e6.near?(1e6+1, 1e-5)
    assert (1e6+1).near?(1e6, 1e-5)
    refute 1e4.near?(1e4+1, 1e-5)
    refute (1e4+1).near?(1e4, 1e-5)
  end

  def test_large_negative_numbers
    assert (-1e6).near?(-(1e6+1), 1e-5)
    assert (-(1e6+1)).near?(-1e6, 1e-5)
    refute (-1e4).near?(-(1e4+1), 1e-5)
    refute (-(1e4+1)).near?(-1e4, 1e-5)
  end

  def test_near_1
    assert 1.0000001.near?(1.0000002, 1e-5)
    assert 1.0000002.near?(1.0000001, 1e-5)
    refute 1.0002.near?(1.0001, 1e-5)
    refute 1.0001.near?(1.0002, 1e-5)
  end

  def test_near_negative_1
    assert (-1.0000001).near?(-1.0000002, 1e-5)
    assert (-1.0000002).near?(-1.0000001, 1e-5)
    refute (-1.0002).near?(-1.0001, 1e-5)
    refute (-1.0001).near?(-1.0002, 1e-5)
  end

  def test_between_1_and_0
    assert 0.000000001000001.near?(0.000000001000002, 1e-5)
    assert 0.000000001000002.near?(0.000000001000001, 1e-5)
    refute 0.000000000001002.near?(0.000000000001001, 1e-5)
    refute 0.000000000001001.near?(0.000000000001002, 1e-5)
  end

  def test_between_negative_1_and_0
    assert (-0.000000001000001).near?(-0.000000001000002, 1e-5)
    assert (-0.000000001000002).near?(-0.000000001000001, 1e-5)
    refute (-0.000000000001002).near?(-0.000000000001001, 1e-5)
    refute (-0.000000000001001).near?(-0.000000000001002, 1e-5)
  end

  def test_zeros
    assert 0.0.near?(0.0, 1e-5)
    assert 0.0.near?(-0.0, 1e-5)
    assert (-0.0).near?(0.0, 1e-5)
    assert (-0.0).near?(-0.0, 1e-5)
    refute 0.00000001.near?(0.0, 1e-5)
    refute 0.0.near?(0.00000001, 1e-5)
    refute (-0.00000001).near?(0.0, 1e-5)
    refute 0.0.near?(-0.00000001, 1e-5)

    assert 0.0.near?(1e-40, 0.01)
    assert 1e-40.near?(0.0, 0.01)
    #refute 1e-40.near?(0.0, 1e-6)
    #refute 0.0.near?(1e-40, 1e-6)

    #assert 0.0.near?(-1e40, 0.1)
    #assert -1e40.near?(0.0, 0.1)
    #refute -1e-40.near?(0.0, 1e-8)
    #refute 0.0.near?(-1e-40, 1e-8)
  end

  def test_infinities
    assert Float::INFINITY.near?(Float::INFINITY, 1e-5)
    assert (-Float::INFINITY).near?(-Float::INFINITY, 1e-5)
    refute (-Float::INFINITY).near?(Float::INFINITY, 1e-5)
    refute Float::INFINITY.near?(Float::MAX, 1e-5)
    refute (-Float::INFINITY).near?(-Float::MAX, 1e-5)
  end

  def test_nan
    refute Float::NAN.near?(Float::NAN, 1e-5)
    refute Float::NAN.near?(0.0, 1e-5)
    refute (-0.0).near?(Float::NAN, 1e-5)
    refute Float::NAN.near?(-0.0, 1e-5)

    refute Float::NAN.near?(Float::INFINITY, 1e-5)
    refute Float::INFINITY.near?(Float::NAN, 1e-5)
    refute Float::NAN.near?(-Float::INFINITY, 1e-5)
    refute (-Float::INFINITY).near?(Float::NAN, 1e-5)

    refute Float::NAN.near?(Float::MAX, 1e-5)
    refute Float::MAX.near?(Float::NAN, 1e-5)
    refute Float::NAN.near?(-Float::MAX, 1e-5)
    refute (-Float::MAX).near?(Float::NAN, 1e-5)

    refute Float::NAN.near?(Float::MIN, 1e-5)
    refute Float::MIN.near?(Float::NAN, 1e-5)
    refute Float::NAN.near?(-Float::MIN, 1e-5)
    refute (-Float::MIN).near?(Float::NAN, 1e-5)
  end

  def test_opposites
    refute 1.000000001.near?(-1.0, 1e-5)
    refute (-1.0).near?(1.000000001, 1e-5)
    refute (-1.000000001).near?(1.0, 1e-5)
    refute 1.0.near?(-1.000000001, 1e-5)
    assert (10 * Float::MIN).near?(10 * -Float::MIN)
    #refute (10000 * Float::MIN).near?(10000 * -Float::MIN)
  end

  def test_close_to_zero
    refute 0.000000001.near?(-Float::MIN, 1e-5)
    refute 0.000000001.near?(Float::MIN, 1e-5)
    refute Float::MIN.near?(0.000000001, 1e-5)
    refute (-Float::MIN).near?(0.000000001, 1e-5)

    refute 1e-9.near?(-Float::MIN)
    refute 1e-9.near?(Float::MIN)
    refute Float::MIN.near?(1e-9)
    refute (-Float::MIN).near?(1e-9)
  end
end
