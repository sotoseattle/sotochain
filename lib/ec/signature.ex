defmodule Ec.Signature do
  alias Ec.Point
  alias Ec.Signature
  alias Util
  import Integer, only: [mod: 2]

  defstruct r: nil, s: nil

  @g Ec.Point256.spc256k1_g()
  @n Ec.Point256.spc256k1_n()

  @type t(r, s) :: %Signature{r: r, s: s}
  @type t :: %Signature{r: pos_integer(), s: pos_integer()}

  # Adapted from Curvy: https://github.com/libitx/curvy (deterministic_k))
  # Implements RFC 6979 {r,s} values from deterministically generated k
  # Added s > n/2 because "It turns out that using low values of s will get 
  # miner nodes to relay transactions instead of commit them."
  def sign(hash, private_key) do
    xoxo = :binary.encode_unsigned(hash)

    v = :binary.copy(<<1>>, 32)
    k = :binary.copy(<<0>>, 32)

    k =
      :crypto.mac(
        :hmac,
        :sha256,
        k,
        <<v::binary, 0, private_key::big-size(256), xoxo::binary>>
      )

    v = :crypto.mac(:hmac, :sha256, k, v)

    k =
      :crypto.mac(
        :hmac,
        :sha256,
        k,
        <<v::binary, 1, private_key::big-size(256), xoxo::binary>>
      )

    v = :crypto.mac(:hmac, :sha256, k, v)

    Enum.reduce_while(0..1000, {k, v}, fn i, {k, v} ->
      if i == 1000, do: throw({:error, "tried 1000 k values, all were invalid"})
      v = :crypto.mac(:hmac, :sha256, k, v)

      case v do
        <<t::big-size(256)>> when 0 < t and t < @n ->
          r = Point.dot(t, @g).x.n

          s = (Util.powo(t, @n - 2, @n) * (hash + r * private_key)) |> mod(@n)

          if r == 0 or s == 0 or s > @n / 2,
            do: {:cont, {k, v}},
            else: {:halt, %Signature{r: r, s: s}}

        _ ->
          k = :crypto.mac(:hmac, :sha256, k, <<v::binary, 0>>)
          v = :crypto.mac(:hmac, :sha256, k, v)
          {:cont, {k, v}}
      end
    end)
  end

  @doc """
  Verify a hashed message in integer form, with reconstituted signature and
  public key.
  """
  @spec verify(integer, Signature.t(), Point.t()) :: {:ok, String.t()} | {:error, String.t()}
  def verify(hash, %Signature{r: r, s: s} = sign, key) when is_integer(hash) do
    s_inv = Util.powo(s, @n - 2, @n)
    u = (hash * s_inv) |> mod(@n)
    v = (r * s_inv) |> mod(@n)

    u
    |> Point.dot(@g)
    |> Point.add(Point.dot(v, key))
    |> confirm(sign.r)
  end

  defp confirm(%Point{x: %{n: n}}, n), do: {:ok, "signature verified"}
  defp confirm(_, _), do: {:error, "unable to verify signature"}

  @doc """
  Serialization in hex with DER standard. We serialize r and s.
  Start with a header of (30) then the total size, then for each (r and s), 
  a marker (02) followed by its size (in hex) and
  maybe a (00) if the first byte is over 80, and the hex of the r/s.
  """
  def serialize(signature) do
    bin = der_int(signature.r) <> der_int(signature.s)

    <<48, byte_size(bin)::integer, bin::binary>> |> :binary.encode_hex()
  end

  defp der_int(int) do
    bin = Util.int_2_bin(int)
    first = :binary.first(bin)

    <<2, der_bin(bin, first)::binary, bin::binary>>
  end

  defp der_bin(bin, first) when first <= 80, do: <<byte_size(bin)>>
  defp der_bin(bin, _first), do: <<byte_size(bin) + 1, 0>>

  @doc """
  Parsing a signature differs from serializing in that it may include a
  sighash byte if it comes from pre-existing transactions
  https://raghavsood.com/blog/2018/06/10/bitcoin-signature-types-sighash
  """
  @spec parse(String.t()) :: Signature.t()
  def parse(sign_hex) do
    <<
      48,
      _len::integer,
      2::integer,
      len_r::integer,
      r::bytes-size(len_r),
      2::integer,
      len_s::integer,
      s::bytes-size(len_s),
      _sighash::binary
    >> = :binary.decode_hex(sign_hex)

    %Signature{r: decapitate(r), s: decapitate(s)}
  end

  defp decapitate(<<0, n::big>>), do: n
  defp decapitate(n), do: :binary.decode_unsigned(n)
end
