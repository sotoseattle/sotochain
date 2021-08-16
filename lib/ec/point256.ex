defmodule Ec.Point256 do
  alias Util
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

  @doc """
  A point on the specific curve SPC256K1 projected onto a finite field with an
  specific big prime number.
  """
  def new(x, y) when is_binary(x) and is_binary(y) do
    new(Util.hex_2_int(x), Util.hex_2_int(y))
  end

  def new(x, y) when is_integer(x) and is_integer(y) do
    Point.new(
      fi_256(x),
      fi_256(y),
      @g_spc256k1.a,
      @g_spc256k1.b
    )
  end

  def new(%Fifi{} = x, %Fifi{} = y) do
    Point.new(x, y, @g_spc256k1.a, @g_spc256k1.b)
  end

  defp fi_256(n) when is_integer(n) do
    Fifi.new(n, @k_spc256k1)
  end

  def infinite_point(),
    do: Point.new(nil, nil, @g_spc256k1.a, @g_spc256k1.b)

  def spc256k1_g(), do: @g_spc256k1
  def spc256k1_n(), do: @n_spc256k1

  @doc """
  Serialization of a point according to the SEC format 
    - uncompressed format starts with (04)
    - compressed format starts with (02) or (03) depending on y
      because if we have x, we know that y can only be one of two values, 
      above or below the abscissa line
  """
  def serialize(point, compressed \\ true)

  def serialize(%Point{x: x, y: y}, true) do
    case Integer.mod(y.n, 2) do
      0 -> <<2::integer, x.n::big-size(256)>>
      _ -> <<3::integer, x.n::big-size(256)>>
    end
  end

  def serialize(%Point{x: x, y: y}, false) do
    <<4::integer, x.n::big-size(256), y.n::big-size(256)>>
  end

  @doc """
  Rebuild a point on SPC256K1 from its serialized form.
  """
  def deserialize("04" <> serial_p) do
    {x, y} = String.split_at(serial_p, 64)
    new(x, y)
  end

  def deserialize(serial_p) do
    {tipo, x} = String.split_at(serial_p, 2)
    x = Util.hex_2_int(x)

    wip =
      fi_256(x)
      |> Fifi.expf(3)
      |> Fifi.addf(@g_spc256k1.b)
      |> Fifi.sqrtf()

    y = get_y(wip, tipo, Integer.mod(wip.n, 2))

    new(x, y)
  end

  defp get_y(fi, "02", 0), do: fi.n
  defp get_y(fi, "02", _), do: @k_spc256k1 - fi.n
  defp get_y(fi, "03", 0), do: @k_spc256k1 - fi.n
  defp get_y(fi, "03", _), do: fi.n

  @doc """
  Consecutive double hashing (sha256 and ripemd160) of a serialized point
  """
  def hash160(point, compressed \\ true) do
    point
    |> serialize(compressed)
    |> Util.hash160()
  end

  @doc """
  An address is a reduction of a point through serialization and hashing.
  The address has:
    - the type of network (main: (6F), testnet: (00))
    - the hash of the serialized point
    - a checksum with 4 bytes of a doubled hash
  """
  def address(point, compressed \\ true, testnet \\ false) do
    bino = <<
      net_prefix(testnet)::binary,
      hash160(point, compressed)::binary
    >>

    <<bino::binary, checksum(bino)::binary>>
    |> Util.encode_base58()
  end

  def checksum(b) do
    b = :crypto.hash(:sha256, b)
    b = :crypto.hash(:sha256, b)
    <<cho::binary-size(4), _rest::binary>> = b
    cho
  end

  defp net_prefix(true), do: <<111::integer>>
  defp net_prefix(_), do: <<0::integer>>
end
