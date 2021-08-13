defmodule Fasto do
  import Bitwise

  @moduledoc """
  Interesting algorithms that scale up to big numbers
  The Elop addition and pow operations are very expensive, 
  so we use a binary expansion algorithm to perform the operation 
  in ~log2(scalar).
  """

  @doc """
  Dot product of eliptic curve points projected into finite fields
  We start with 0 (infinity) and add the eliptic point through
  binary expansion.
  """
  def doto(%Elip{a: a, b: b} = ep, scalar) do
    recurro(scalar, ep, Elip.infinite_point(a, b), &Elip.add(&1, &2))
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
end
