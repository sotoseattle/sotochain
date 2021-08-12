defmodule Elip do
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
        slope = Fe.expf(x, 2) |> Fe.dotf(3) |> Fe.addf(a) |> Fe.divf(Fe.dotf(2, y))
        x3 = Fe.expf(slope, 2) |> Fe.subf(Fe.dotf(2, x))
        y3 = Fe.subf(x, x3) |> Fe.prodf(slope) |> Fe.subf(y)

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
        slope = Fe.subf(y2, y1) |> Fe.divf(Fe.subf(x2, x1))
        x3 = Fe.expf(slope, 2) |> Fe.subf(x1) |> Fe.subf(x2)
        y3 = Fe.subf(x1, x3) |> Fe.prodf(slope) |> Fe.subf(y1)

        Elip.new(x3, y3, a, b)

      _ ->
        :error
    end
  end

  def dot(ep, n), do: doto(ep, n, ep)
  def dot(n, ep), do: doto(ep, n, ep)
  defp doto(%Elip{}, 1, acc), do: acc
  defp doto(ep, n, acc), do: doto(ep, n - 1, Elip.add(acc, ep))

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

  defp infinite_point(a, b), do: %Elip{x: nil, y: nil, a: a, b: b}

  def tipo(%Fe{}, %Fe{}, %Fe{}, %Fe{}), do: :fe

  def tipo(nil, nil, a, b) when is_number(a) and is_number(b), do: :int

  def tipo(x, y, a, b)
      when is_number(x) and is_number(y) and is_number(a) and is_number(b) do
    :int
  end

  def tipo(_, _, _, _), do: :error

  defp modo(floato, integro), do: Integer.mod(floato, integro)
end
