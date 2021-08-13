defmodule Ec.Fasto do
  import Bitwise
  alias Ec.Point

  @moduledoc """
  Algorithms to scale up certain operations for big numbers.
  The point addition with fifis, and pow of huge numbers are very expensive, 
  so we use binary expansion algorithm to perform in ~log2(scalar).
  """

  @doc """
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
end
