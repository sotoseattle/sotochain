defmodule Util do
  import Bitwise
  alias Ec.Point

  @base_58_alphabet "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
                    |> String.graphemes()

  @doc """
  Algorithm to scale up operations for big numbers.
  The point addition with fifis of huge numbers is very expensive, 
  so we use binary expansion algorithm to perform in ~log2(scalar).
  Dot product of eliptic curve points projected into finite fields
  We start with 0 (infinity) and add the eliptic point through
  binary expansion.
  """
  def doto(%Point{a: a, b: b} = ep, scalar) do
    recurro(scalar, ep, Point.infinite_point(a, b), &Point.add(&1, &2))
  end

  @doc """
  Exponentiation of big n. We start at 1 and multiply through binary expansion.
  """
  def powo(x, y, k) do
    recurro(y, x, 1, &Integer.mod(&1 * &2, k))
  end

  defp recurro(0, _, acc, _fx), do: acc

  defp recurro(scalar, current, acc, fx) do
    acc = puncho(rightmost_bit(scalar), acc, current, fx)

    current = fx.(current, current)

    recurro(scalar >>> 1, current, acc, fx)
  end

  defp rightmost_bit(int), do: int |> Integer.digits(2) |> List.last()

  defp puncho(1, a, b, fx), do: fx.(a, b)
  defp puncho(0, a, _, _funciono), do: a

  @doc """
  Like base 64 without number 0 and letters O, l, I (to avoid confussion)
  BEWARE: I am not prepending zeroes because I am converting from int !!!
  """
  def encode_base58(bin) when is_binary(bin) do
    {bin_n, zeroes_n} = leading_zeroes(bin, 0)

    hex58 =
      bin_n
      |> :binary.encode_hex()
      |> hex_2_int()
      |> num_base58()

    String.duplicate("1", zeroes_n) <> hex58
  end

  defp num_base58(num, acc \\ [])
  defp num_base58(0, acc), do: acc |> Enum.join()

  defp num_base58(num, acc) do
    num_base58(
      Integer.floor_div(num, 58),
      [Enum.at(@base_58_alphabet, Integer.mod(num, 58)) | acc]
    )
  end

  defp leading_zeroes(<<0>> <> hex, c), do: leading_zeroes(hex, c + 1)
  defp leading_zeroes(hex, c), do: {hex, c}

  def hash160(message) do
    :crypto.hash(:ripemd160, :crypto.hash(:sha256, message))
  end

  def int_2_hex_big(i) do
    i |> :binary.encode_unsigned(:big) |> :binary.encode_hex()
  end

  def hex_2_int(hex) do
    hex |> Integer.parse(16) |> elem(0)
  end
end
