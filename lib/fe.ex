defmodule Fe do
  @moduledoc """
  A field element
  """

  defstruct k: nil, n: nil

  @doc "A field element is defined by a positive integer (n) and a prime (k)"
  def new(n, p) when n >= 0 and n < p, do: %Fe{n: n, k: p}
  def new(_, _), do: :error

  @doc "Negative of a field element"
  def negf(%Fe{n: x, k: p}), do: %Fe{n: Integer.mod(-x, p), k: p}

  @doc "Equality among field elements is defined for all attributes"
  def equals(fea, feo), do: fea == feo

  @doc "Not equality of field elements"
  def ne(fea, feo), do: not Fe.equals(fea, feo)

  @doc "Addition of field elements"
  def addf(%Fe{n: x, k: p}, %Fe{n: y, k: p}),
    do: %Fe{n: (x + y) |> Integer.mod(p), k: p}

  @doc " Subtracttion of field elements "
  def subf(%Fe{n: x, k: p}, %Fe{n: y, k: p}) do
    %Fe{n: Integer.mod(x - y, p), k: p}
  end

  @doc "Multiplication of field elements"
  def prodf(%Fe{n: x, k: p} = feo, %Fe{n: y, k: p}) do
    %{feo | n: (x * y) |> Integer.mod(p)}
  end

  @doc "Scalar product"
  def dotf(%Fe{n: x, k: p}, n) when is_number(n), do: %Fe{n: (x * n) |> Integer.mod(p), k: p}
  def dotf(n, %Fe{n: x, k: p}) when is_number(n), do: %Fe{n: (x * n) |> Integer.mod(p), k: p}

  @doc "Exponentiation of field element"
  def expf(feo, y) when y >= 0 do
    %{feo | n: Integer.pow(feo.n, y) |> Integer.mod(feo.k)}
  end

  def expf(feo, y) when y < 0 do
    %{feo | n: Integer.pow(feo.n, Integer.mod(y, feo.k - 1)) |> Integer.mod(feo.k)}
  end

  @doc "Division of field elements"
  def divf(%Fe{n: x, k: p}, %Fe{n: y, k: p}) do
    %Fe{n: (x * Integer.pow(y, p - 2)) |> Integer.mod(p), k: p}
  end
end
