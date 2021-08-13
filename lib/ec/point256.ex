defmodule Ec.Point256 do
  alias Ec.Fifi
  alias Ec.Point
  alias Ec.Fasto

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

  def fi_256(n) when is_integer(n),
    do: Fifi.new(n, @k_spc256k1)

  def new(x, y) when is_binary(x) and is_binary(y),
    do: new(hex_int(x), hex_int(y))

  def new(x, y) when is_integer(x) and is_integer(y),
    do:
      Point.new(
        fi_256(x),
        fi_256(y),
        fi_256(@a_spc256k1),
        fi_256(@b_spc256k1)
      )

  def new(%Fifi{} = x, %Fifi{} = y),
    do: Point.new(x, y, fi_256(@a_spc256k1), fi_256(@b_spc256k1))

  def dot(point, n) when is_integer(n),
    do: Point.dot(point, Integer.mod(n, @n_spc256k1))

  def dot(n, point) when is_integer(n),
    do: Point.dot(point, Integer.mod(n, @n_spc256k1))

  def infinite_point(),
    do: Point.new(nil, nil, fi_256(@a_spc256k1), fi_256(@b_spc256k1))

  def is_verified(p_key: public_key, hash: z, r: r, s: s) do
    s_inv = Fasto.powo(s, @n_spc256k1 - 2, @n_spc256k1)
    u = (z * s_inv) |> Integer.mod(@n_spc256k1)
    v = (r * s_inv) |> Integer.mod(@n_spc256k1)

    big_R = Point.dot(u, @g_spc256k1) |> Point.add(Point.dot(v, public_key))

    big_R.x.n == r
  end

  def hex_int(hex), do: hex |> Integer.parse(16) |> elem(0)
end
