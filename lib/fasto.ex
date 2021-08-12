defmodule Fasto do
  import Bitwise

  @moduledoc """
  Interesting algorithms that scale up to big numbers
  """

  @doc """
  Dot product of eliptic curve points projected into finite fields
  The addition operation is very expensive, so we use a binary expansion
  algorithm to perform the operation in ~log2(scalar).
  """
  def doto(%Elip{a: a, b: b} = ep, scalar) do
    recurro(scalar, ep, Elip.infinite_point(a, b))
  end

  defp recurro(0, _, result), do: result

  defp recurro(scalar, current, result) do
    result = addo(rightmost_bit(scalar), result, current)
    current = Elip.add(current, current)

    recurro(scalar >>> 1, current, result)
  end

  defp rightmost_bit(int), do: int |> Integer.digits(2) |> List.last()

  defp addo(1, a, b), do: Elip.add(a, b)
  defp addo(0, a, _), do: a
end
