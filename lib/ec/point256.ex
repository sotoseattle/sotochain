defmodule Ec.Point256 do
  alias Ec.Fifi
  alias Ec.Point

  @moduledoc "Point256 in eliptic curve projected unto finite field"

  @k_spc256k1 Integer.pow(2, 256) - Integer.pow(2, 32) - 977
  @a_spc256k1 0
  @b_spc256k1 7
  @n_spc256k1 115_792_089_237_316_195_423_570_985_008_687_907_852_837_564_279_074_904_382_605_163_141_518_161_494_337
  @g_spc256k1 Point.new(
                Fifi.new(
                  55_066_263_022_277_343_669_578_718_895_168_534_326_250_603_453_777_594_175_500_187_360_389_116_729_240,
                  @k_spc256k1
                ),
                Fifi.new(
                  32_670_510_020_758_816_978_083_085_130_507_043_184_471_273_380_659_243_275_938_904_335_757_337_482_424,
                  @k_spc256k1
                ),
                Fifi.new(@a_spc256k1, @k_spc256k1),
                Fifi.new(@b_spc256k1, @k_spc256k1)
              )

  defstruct x: nil, y: nil, a: nil, b: nil

  def new(x, y) when is_binary(x) and is_binary(y),
    do: new(hex_int(x), hex_int(y))

  def new(x, y) when is_integer(x) and is_integer(y),
    do: Point.new(fi_256(x), fi_256(y), @g_spc256k1.a, @g_spc256k1.b)

  def new(%Fifi{} = x, %Fifi{} = y),
    do: Point.new(x, y, @g_spc256k1.a, @g_spc256k1.b)

  defp fi_256(n) when is_integer(n), do: Fifi.new(n, @k_spc256k1)

  def infinite_point(),
    do: Point.new(nil, nil, @g_spc256k1.a, @g_spc256k1.b)

  def hex_int(hex), do: hex |> Integer.parse(16) |> elem(0)

  def spc256k1_g(), do: @g_spc256k1
  def spc256k1_n(), do: @n_spc256k1

  @doc "Serialization SEC format in compressed and uncompressed format"
  def sec(point, compressed \\ true)

  def sec(%Point{x: x, y: y}, true) do
    case Integer.mod(y.n, 2) do
      0 -> "02#{int_2_hex_big(x.n)}"
      _ -> "03#{int_2_hex_big(x.n)}"
    end
  end

  def sec(%Point{x: x, y: y}, false),
    do: "04#{int_2_hex_big(x.n)}#{int_2_hex_big(y.n)}"

  defp int_2_hex_big(i),
    do: i |> :binary.encode_unsigned(:big) |> :binary.encode_hex()

  def parse("04" <> psec) do
    {x, y} = String.split_at(psec, 64)
    new(x, y)
  end

  def parse(psec) do
    {tipo, x} = String.split_at(psec, 2)
    x = Integer.parse(x, 16) |> elem(0)

    wip =
      fi_256(x)
      |> Fifi.expf(3)
      |> Fifi.addf(@g_spc256k1.b)
      |> Fifi.sqrtf()

    y = get_y(wip, tipo, Integer.mod(wip.n, 2))

    new(x, y)
  end

  def get_y(fi, "02", 0), do: fi.n
  def get_y(fi, "02", _), do: @k_spc256k1 - fi.n
  def get_y(fi, "03", 0), do: @k_spc256k1 - fi.n
  def get_y(fi, "03", _), do: fi.n
end
