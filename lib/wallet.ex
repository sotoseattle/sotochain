defmodule Wallet do
  alias Ec.Point256
  alias Ec.Point
  alias Ec.Fasto

  defstruct private_key: nil, public_key: nil, g: nil, n: nil

  @defaulto "lalailo"
  @g Point256.spc256k1_g()
  @n Point256.spc256k1_n()

  def new(secret \\ @defaulto) when is_binary(secret) do
    e = hasho(secret) |> Integer.mod(@n)
    p = Point.dot(e, @g)
    %__MODULE__{private_key: e, public_key: p}
  end

  def sign(wallet, message) do
    message
    |> hasho()
    |> deterministic_k_rfc6979(wallet.private_key)
  end

  def verify(public_key: p_key, hash: z, signature: %{r: r, s: s}) do
    s_inv = Fasto.powo(s, @n - 2, @n)
    u = (z * s_inv) |> Integer.mod(@n)
    v = (r * s_inv) |> Integer.mod(@n)

    Point.dot(u, @g)
    |> Point.add(Point.dot(v, p_key))
    |> check_R(r)
  end

  defp check_R(%{x: %{n: r}}, r), do: {:ok, "signature verified"}
  defp check_R(_, _), do: {:error, "unable to verify signature"}

  # Adapted from Curvy: https://github.com/libitx/curvy (deterministic_k))
  # Implements RFC 6979 {r,s} values from deterministically generated k
  # Added s > n/2 because "It turns out that using low values of s will get 
  # miner nodes to relay transactions instead of commit them."
  def deterministic_k_rfc6979(hash, private_key) do
    xoxo = :binary.encode_unsigned(hash)

    v = :binary.copy(<<1>>, 32)
    k = :binary.copy(<<0>>, 32)

    k = :crypto.mac(:hmac, :sha256, k, <<v::binary, 0, private_key::integer, xoxo::binary>>)
    v = :crypto.mac(:hmac, :sha256, k, v)

    k = :crypto.mac(:hmac, :sha256, k, <<v::binary, 1, private_key::integer, xoxo::binary>>)
    v = :crypto.mac(:hmac, :sha256, k, v)

    Enum.reduce_while(0..1000, {k, v}, fn i, {k, v} ->
      if i == 1000, do: throw("Tried 1000 k values, all were invalid")
      v = :crypto.mac(:hmac, :sha256, k, v)

      case v do
        <<t::big-size(256)>> when 0 < t and t < @n ->
          r = Point.dot(t, @g).x.n
          s = (Fasto.powo(t, @n - 2, @n) * (hash + r * private_key)) |> Integer.mod(@n)

          if r == 0 or s == 0 or s > @n / 2,
            do: {:cont, {k, v}},
            else: {:halt, %{r: r, s: s}}

        _ ->
          k = :crypto.mac(:hmac, :sha256, k, <<v::binary, 0>>)
          v = :crypto.mac(:hmac, :sha256, k, v)
          {:cont, {k, v}}
      end
    end)
  end

  def hasho(str) do
    :crypto.hash(:sha256, str) |> Base.encode16() |> Integer.parse(16) |> elem(0)
  end
end
