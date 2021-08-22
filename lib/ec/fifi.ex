defmodule Ec.Fifi do
  @moduledoc "A finite field element"

  alias Ec.Fifi
  alias Util

  defstruct n: nil, k: nil

  @type t(n, k) :: %Fifi{n: n, k: k}
  @type t :: %Fifi{n: pos_integer, k: pos_integer}

  @doc """
  A finite field element is defined by a positive integer (n) and a prime (k)
  """
  @spec new(pos_integer(), pos_integer()) :: Fifi.t()
  def new(n, p) when n >= 0 and n < p, do: %Fifi{n: n, k: p}
  # def new(_, _), do: :error

  @doc "Negative of a finite field element"
  @spec negf(Fifi.t()) :: Fifi.t()
  def negf(%Fifi{n: x, k: p} = feo), do: %{feo | n: Integer.mod(-x, p)}

  @doc "Addition of finite field elements"
  @spec addf(Fifi.t(), Fifi.t()) :: Fifi.t()
  def addf(%Fifi{n: x, k: p} = feo, %Fifi{n: y, k: p}),
    do: %{feo | n: (x + y) |> Integer.mod(p)}

  @doc "Subtracttion of finite field elements"
  @spec subf(Fifi.t(), Fifi.t()) :: Fifi.t()
  def subf(%Fifi{n: x, k: p} = feo, %Fifi{n: y, k: p}) do
    %{feo | n: Integer.mod(x - y, p)}
  end

  @doc "Multiplication of finite field elements"
  @spec prodf(Fifi.t(), Fifi.t()) :: Fifi.t()
  def prodf(%Fifi{n: x, k: p} = feo, %Fifi{n: y, k: p}) do
    %{feo | n: (x * y) |> Integer.mod(p)}
  end

  @doc "Scalar product"
  @spec dotf(Fifi.t(), pos_integer) :: Fifi.t()
  def dotf(%Fifi{n: x, k: p}, n) when is_number(n), do: %Fifi{n: (x * n) |> Integer.mod(p), k: p}

  @spec dotf(pos_integer, Fifi.t()) :: Fifi.t()
  def dotf(n, %Fifi{n: x, k: p}) when is_number(n), do: %Fifi{n: (x * n) |> Integer.mod(p), k: p}

  @doc "Exponentiation of finite field element"
  @spec expf(Fifi.t(), pos_integer) :: Fifi.t()
  def expf(feo, y) when y >= 0 do
    %{feo | n: Util.powo(feo.n, y, feo.k)}
  end

  @spec expf(pos_integer, Fifi.t()) :: Fifi.t()
  def expf(%Fifi{n: n, k: k} = feo, y) when y < 0 do
    %{feo | n: Util.powo(n, Integer.mod(y, k - 1), k)}
  end

  @spec sqrtf(Fifi.t()) :: Fifi.t()
  def sqrtf(%Fifi{n: n, k: k} = feo) do
    if Integer.mod(k, 4) == 3 do
      %{feo | n: Util.powo(n, Integer.floor_div(k + 1, 4), k)}
    else
      {:error, "sqrt of fifi... computer says no"}
    end
  end

  @doc "Division of finite field elements"
  @spec divf(Fifi.t(), Fifi.t()) :: Fifi.t()
  def divf(%Fifi{n: x, k: k} = feo, %Fifi{n: y, k: k}) do
    %{feo | n: (x * Util.powo(y, k - 2, k)) |> Integer.mod(k)}
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
