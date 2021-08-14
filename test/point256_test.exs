defmodule Point256Test do
  use ExUnit.Case
  alias Ec.Fifi
  alias Ec.Point256
  alias Ec.Point

  doctest Ec.Point

  test "in the real deal" do
    x =
      55_066_263_022_277_343_669_578_718_895_168_534_326_250_603_453_777_594_175_500_187_360_389_116_729_240

    y =
      32_670_510_020_758_816_978_083_085_130_507_043_184_471_273_380_659_243_275_938_904_335_757_337_482_424

    n =
      115_792_089_237_316_195_423_570_985_008_687_907_852_837_564_279_074_904_382_605_163_141_518_161_494_337

    assert g = Point256.new(x, y)
    assert Point.dot(g, n) == Point256.infinite_point()
  end
end
