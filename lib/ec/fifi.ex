defmodule Ec.Fifi do
  @moduledoc "A finite field element"

  alias Ec.Fifi
  alias Ec.Fasto

  defstruct n: nil, k: nil

  @doc "A field element is defined by a positive integer (n) and a prime (k)"
  def new(n, p) when n >= 0 and n < p, do: %Fifi{n: n, k: p}
  def new(_, _), do: :error

  @doc "Negative of a field element"
  def negf(%Fifi{n: x, k: p} = feo), do: %{feo | n: Integer.mod(-x, p)}

  @doc "Addition of field elements"
  def addf(%Fifi{n: x, k: p} = feo, %Fifi{n: y, k: p}),
    do: %{feo | n: (x + y) |> Integer.mod(p)}

  @doc " Subtracttion of field elements "
  def subf(%Fifi{n: x, k: p} = feo, %Fifi{n: y, k: p}) do
    %{feo | n: Integer.mod(x - y, p)}
  end

  @doc "Multiplication of field elements"
  def prodf(%Fifi{n: x, k: p} = feo, %Fifi{n: y, k: p}) do
    %{feo | n: (x * y) |> Integer.mod(p)}
  end

  @doc "Scalar product"
  def dotf(%Fifi{n: x, k: p}, n) when is_number(n), do: %Fifi{n: (x * n) |> Integer.mod(p), k: p}
  def dotf(n, %Fifi{n: x, k: p}) when is_number(n), do: %Fifi{n: (x * n) |> Integer.mod(p), k: p}

  @doc "Exponentiation of field element"
  def expf(feo, y) when y >= 0 do
    %{feo | n: Fasto.powo(feo.n, y, feo.k)}
  end

  def expf(%Fifi{n: n, k: k} = feo, y) when y < 0 do
    %{feo | n: Fasto.powo(n, Integer.mod(y, k - 1), k)}
  end

  @doc "Division of field elements"
  def divf(%Fifi{n: x, k: k} = feo, %Fifi{n: y, k: k}) do
    %{feo | n: (x * Fasto.powo(y, k - 2, k)) |> Integer.mod(k)}
  end

  defimpl Inspect, for: Fifi do
    def inspect(fi, _opts) do
      """
      Finite Field Element:
        Number: #{fi.n}
        Prime: #{fi.k}
      """
    end
  end

  defimpl String.Chars, for: Fifi do
    def to_string(fi), do: "Fifi: {n: #{fi.n}, prime: #{fi.k}}"
  end
end
