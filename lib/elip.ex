defmodule Elip do
  import Bitwise
  alias Fasto

  @moduledoc """
  A point in an eliptic curve
  """
  defstruct x: nil, y: nil, a: nil, b: nil

  @doc """
  A point {x, y} in an eliptic curve defined by params {a, b}
  iex> Elip.new 18, 77, 5, 7
  %Elip{a: 5, b: 7, x: 18, y: 77}

  iex> Elip.new(2, 4, 5, 7)
  {:error, "point {x, y} ∌ y^2 = x^3 + ax + b"}

  iex> x = Fe.new(192, 223)
  iex> y = Fe.new(105, 223)
  iex> a = Fe.new(0, 223)
  iex> b = Fe.new(7, 223)
  iex> Elip.new(x, y, a, b)
  %Elip{
  a: %Fe{n: 0, k: 223},
  b: %Fe{n: 7, k: 223},
  x: %Fe{n: 192, k: 223},
  y: %Fe{n: 105, k: 223}
  }
  """
  def new(nil, nil, a, b), do: %Elip{x: nil, y: nil, a: a, b: b}

  def new(x, y, a, b) do
    if is_in_curve(x, y, a, b) do
      %Elip{x: x, y: y, a: a, b: b}
    else
      {:error, "point {x, y} ∌ y^2 = x^3 + ax + b"}
    end
  end

  @doc """
  Addition by point at infinity (de facto zero) equals the point
  iex> Elip.add(Elip.new(-1, -1, 5, 7), Elip.new(nil, nil, 5, 7))
  %Elip{x: -1, y: -1, a: 5, b: 7}

  Addition of two points with same x means the sum is at infinity
  iex> Elip.add(Elip.new(-1, -1, 5, 7), Elip.new(-1, 1, 5, 7))
  %Elip{x: nil, y: nil, a: 5, b: 7}


  If the two points are equals, then they are at the tangent to the curve
  and we can find the slope and intersection of the 3rd point
  iex> p = Elip.new(-1, -1, 5, 7)
  iex> Elip.add(p, p)
  %Elip{x: 18.0, y: 77.0, a: 5, b: 7}

  If the tangent is the vertical (at y == 0) the intersect is infinity

  In any other case, given two points, the sum can be derived from the
  intersection of the line they form and the eliptic curve
  iex> Elip.add(Elip.new(-1, -1, 5, 7), Elip.new(2, 5, 5, 7))
  %Elip{x: 3.0, y: -7.0, a: 5, b: 7}
  """

  # add p1 and ∞ => p1
  def add(%Elip{x: nil, y: nil, a: a, b: b}, %Elip{a: a, b: b} = p2), do: p2
  def add(%Elip{a: a, b: b} = p1, %Elip{x: nil, y: nil, a: a, b: b}), do: p1

  # adding a tangent at y == 0 => ∞
  def add(%Elip{y: 0, a: a, b: b} = p1, p1), do: infinite_point(a, b)

  # adding the same point twice => tangent
  def add(%Elip{x: x, y: y, a: a, b: b} = p1, p1) do
    case tipo(x, y, a, b) do
      :int ->
        slope = (3 * :math.pow(x, 2) + a) / (2 * y)
        x3 = :math.pow(slope, 2) - 2 * x
        y3 = slope * (x - x3) - y

        Elip.new(x3, y3, a, b)

      :fe ->
        k = x.k
        s1 = (Fasto.powo(x.n, 2, k) * 3 + a.n) |> Integer.mod(k)
        s2 = Fasto.powo(2 * y.n, k - 2, k)
        slope = (s1 * s2) |> Integer.mod(k)

        xo = (Integer.pow(slope, 2) - 2 * x.n) |> Integer.mod(k)
        yo = ((x.n - xo) * slope - y.n) |> Integer.mod(k)

        x3 = Fe.new(xo, k)
        y3 = Fe.new(yo, k)

        Elip.new(x3, y3, a, b)

      resto ->
        resto
    end
  end

  # adding 2 point with same x => vertical line => ∞
  def add(%Elip{x: x, a: a, b: b}, %Elip{x: x, a: a, b: b}) do
    infinite_point(a, b)
  end

  # adding 2 points all other cases
  def add(%Elip{x: x1, y: y1, a: a, b: b}, %Elip{x: x2, y: y2, a: a, b: b}) do
    case {tipo(x1, y1, a, b), tipo(x2, y2, a, b)} do
      {:int, :int} ->
        slope = (y2 - y1) / (x2 - x1)
        x3 = :math.pow(slope, 2) - x1 - x2
        y3 = slope * (x1 - x3) - y1

        Elip.new(x3, y3, a, b)

      {:fe, :fe} ->
        k = x1.k
        s1 = y2.n - y1.n
        s2 = Fasto.powo(x2.n - x1.n, k - 2, k)
        slope = (s1 * s2) |> Integer.mod(k)

        xo = (Integer.pow(slope, 2) - x1.n - x2.n) |> Integer.mod(k)
        yo = ((x1.n - xo) * slope - y1.n) |> Integer.mod(k)

        x3 = Fe.new(xo, k)
        y3 = Fe.new(yo, k)

        Elip.new(x3, y3, a, b)

      _ ->
        :error
    end
  end

  def dot(%Elip{} = ep, n), do: Fasto.doto(ep, n)
  def dot(n, %Elip{} = ep), do: Fasto.doto(ep, n)

  # Private utility functions

  def is_in_curve(x, y, a, b) do
    case tipo(x, y, a, b) do
      :int ->
        :math.pow(y, 2) == :math.pow(x, 3) + x * a + b

      :fe ->
        Integer.pow(y.n, 2) |> modo(y.k) == (Integer.pow(x.n, 3) + x.n * a.n + b.n) |> modo(x.k)

      _ ->
        {:error, "unrecognized parameters"}
    end
  end

  def infinite_point(a, b), do: %Elip{x: nil, y: nil, a: a, b: b}

  def tipo(%Fe{}, %Fe{}, %Fe{}, %Fe{}), do: :fe

  def tipo(nil, nil, a, b) when is_number(a) and is_number(b), do: :int

  def tipo(x, y, a, b)
      when is_number(x) and is_number(y) and is_number(a) and is_number(b) do
    :int
  end

  def tipo(_, _, _, _), do: :error

  defp modo(floato, integro), do: Integer.mod(floato, integro)

  def chocho() do
    {x, ""} =
      "79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798" |> Integer.parse(16)

    {y, ""} =
      "483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8" |> Integer.parse(16)

    k = Integer.pow(2, 256) - Integer.pow(2, 32) - 977

    gx = Fe.new(x, k)
    gy = Fe.new(y, k)
    a = Fe.new(0, k)
    b = Fe.new(7, k)

    Elip.new(gx, gy, a, b)
  end
end
