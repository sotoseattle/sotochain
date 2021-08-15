defmodule Ec.Signature do
  alias Ec.Point
  alias Ec.Fasto
  alias Ec.Signature

  defstruct r: nil, s: nil, hash: "", key: nil

  def verify(sign, g, n) do
    s_inv = Fasto.powo(sign.s, n - 2, n)
    u = (sign.hash * s_inv) |> Integer.mod(n)
    v = (sign.r * s_inv) |> Integer.mod(n)

    sol =
      Point.dot(u, g)
      |> Point.add(Point.dot(v, sign.key))

    case sol.x.n == sign.r do
      true -> {:ok, "signature verified", sign}
      _ -> {:unverified, "unable to verify signature", sign}
    end
  end

  # Adapted from Curvy: https://github.com/libitx/curvy (deterministic_k))
  # Implements RFC 6979 {r,s} values from deterministically generated k
  # Added s > n/2 because "It turns out that using low values of s will get 
  # miner nodes to relay transactions instead of commit them."
  def sign(hash, wallet) do
    xoxo = :binary.encode_unsigned(hash)

    v = :binary.copy(<<1>>, 32)
    k = :binary.copy(<<0>>, 32)

    k =
      :crypto.mac(:hmac, :sha256, k, <<v::binary, 0, wallet.private_key::integer, xoxo::binary>>)

    v = :crypto.mac(:hmac, :sha256, k, v)

    k =
      :crypto.mac(:hmac, :sha256, k, <<v::binary, 1, wallet.private_key::integer, xoxo::binary>>)

    v = :crypto.mac(:hmac, :sha256, k, v)

    Enum.reduce_while(0..1000, {k, v}, fn i, {k, v} ->
      if i == 1000, do: throw("Tried 1000 k values, all were invalid")
      v = :crypto.mac(:hmac, :sha256, k, v)

      case v do
        <<t::big-size(256)>> when 0 < t and t < wallet.n ->
          r = Point.dot(t, wallet.g).x.n

          s =
            (Fasto.powo(t, wallet.n - 2, wallet.n) * (hash + r * wallet.private_key))
            |> Integer.mod(wallet.n)

          if r == 0 or s == 0 or s > wallet.n / 2,
            do: {:cont, {k, v}},
            else: {:halt, %Signature{r: r, s: s, hash: hash, key: wallet.public_key}}

        _ ->
          k = :crypto.mac(:hmac, :sha256, k, <<v::binary, 0>>)
          v = :crypto.mac(:hmac, :sha256, k, v)
          {:cont, {k, v}}
      end
    end)
  end
end
