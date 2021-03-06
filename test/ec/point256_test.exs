defmodule Point256Test do
  use ExUnit.Case
  alias Ec.Fifi
  alias Ec.Point256
  alias Ec.Point

  doctest Ec.Point

  defp dotx(n), do: Point.dot(n, Point256.spc256k1_g())

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

  test "serialize points as uncompressed for transport" do
    p01 = dotx(5_000)
    sec = p01 |> Point256.serialize(false) |> String.downcase()

    assert sec ==
             "04ffe558e388852f0120e46af2d1b370f85854a8eb0841811ece0e3e03d282d57c315dc72890a4f10a1481c031b03b351b0dc79901ca18a00cf009dbdb157a1d10"

    assert Point256.parse(sec) == p01

    p02 = Integer.pow(2018, 5) |> dotx()
    sec = p02 |> Point256.serialize(false) |> String.downcase()

    assert sec ==
             "04027f3da1918455e03c46f659266a1bb5204e959db7364d2f473bdf8f0a13cc9dff87647fd023c13b4a4994f17691895806e1b40b57f4fd22581a4f46851f3b06"

    assert Point256.parse(sec) == p02

    p03 = "deadbeef12345" |> Util.hex_2_int() |> dotx()
    sec = p03 |> Point256.serialize(false) |> String.downcase()

    assert sec ==
             "04d90cd625ee87dd38656dd95cf79f65f60f7273b67d3096e68bd81e4f5342691f842efa762fd59961d0e99803c61edba8b3e3f7dc3a341836f97733aebf987121"

    assert Point256.parse(sec) == p03
  end

  test "serialize points as compressed for transport" do
    p01 = dotx(5001)
    sec = p01 |> Point256.serialize() |> String.downcase()

    assert sec == "0357a4f368868a8a6d572991e484e664810ff14c05c0fa023275251151fe0e53d1"
    assert Point256.parse(sec) == p01

    p02 = Integer.pow(2019, 5) |> dotx()
    sec = p02 |> Point256.serialize(true) |> String.downcase()

    assert sec == "02933ec2d2b111b92737ec12f1c5d20f3233a0ad21cd8b36d0bca7a0cfa5cb8701"
    assert Point256.parse(sec) == p02

    p03 = "deadbeef54321" |> Util.hex_2_int() |> dotx()
    sec = p03 |> Point256.serialize(true) |> String.downcase()

    assert sec == "0296be5b1292f6c856b3c5654e886fc13511462059089cdf9c479623bfcbe77690"
    assert Point256.parse(sec) == p03
  end

  test "addresses" do
    key = dotx(5002)
    assert Point256.address(key, "whatever", :test) == "mmTPbXQFxboEtNRkwfh6K51jvdtHLxGeMA"

    key = Integer.pow(2020, 5) |> dotx
    assert Point256.address(key, :compr, :test) == "mopVkxp8UhXqRYbCYJsbeE1h1fiF64jcoH"

    key = "12345deadbeef" |> Util.hex_2_int() |> dotx
    assert Point256.address(key, :compr, :main) == "1F1Pn2y6pDb68E5nYJJeba4TLg2U7B6KF1"
  end
end
