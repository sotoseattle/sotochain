defmodule Ec.Pointi do
  @moduledoc "A point in an eliptic curve"

  alias Ec.Pointi

  defstruct x: nil, y: nil, a: nil, b: nil

  @doc """
  A point {x, y} in an eliptic curve defined by params {a, b}
  iex> Pointi.new 18, 77, 5, 7
  %Pointi{a: 5, b: 7, x: 18, y: 77}

  iex> Pointi.new(2, 4, 5, 7)
  {:error, "point {x, y} ∌ y^2 = x^3 + ax + b"}
  """
  def new(nil, nil, a, b), do: %Pointi{x: nil, y: nil, a: a, b: b}

  def new(x, y, a, b) do
    if is_in_curve(x, y, a, b) do
      %Pointi{x: x, y: y, a: a, b: b}
    else
      {:error, "point {x, y} ∌ y^2 = x^3 + ax + b"}
    end
  end

  @doc """
  Addition by point at infinity (de facto zero) equals the point
  iex> Pointi.add(Pointi.new(-1, -1, 5, 7), Pointi.new(nil, nil, 5, 7))
  %Pointi{x: -1, y: -1, a: 5, b: 7}

  Addition of two points with same x means the sum is at infinity
  iex> Pointi.add(Pointi.new(-1, -1, 5, 7), Pointi.new(-1, 1, 5, 7))
  %Pointi{x: nil, y: nil, a: 5, b: 7}


  If the two points are equals, then they are at the tangent to the curve
  and we can find the slope and intersection of the 3rd point
  iex> p = Pointi.new(-1, -1, 5, 7)
  iex> Pointi.add(p, p)
  %Pointi{x: 18.0, y: 77.0, a: 5, b: 7}

  If the tangent is the vertical (at y == 0) the intersect is infinity

  In any other case, given two points, the sum can be derived from the
  intersection of the line they form and the eliptic curve
  iex> Pointi.add(Pointi.new(-1, -1, 5, 7), Pointi.new(2, 5, 5, 7))
  %Pointi{x: 3.0, y: -7.0, a: 5, b: 7}
  """

  # add p1 and ∞ => p1
  def add(%Pointi{x: nil, y: nil, a: a, b: b}, %Pointi{a: a, b: b} = p2), do: p2
  def add(%Pointi{a: a, b: b} = p1, %Pointi{x: nil, y: nil, a: a, b: b}), do: p1

  # adding a tangent at y == 0 => ∞
  def add(%Pointi{y: 0, a: a, b: b} = p1, p1), do: infinite_point(a, b)

  # adding the same point twice => tangent
  def add(%Pointi{x: x, y: y, a: a, b: b} = p1, p1) do
    slope = (3 * :math.pow(x, 2) + a) / (2 * y)
    x3 = :math.pow(slope, 2) - 2 * x
    y3 = slope * (x - x3) - y

    Pointi.new(x3, y3, a, b)
  end

  # adding 2 point with same x => vertical line => ∞
  def add(%Pointi{x: x, a: a, b: b}, %Pointi{x: x, a: a, b: b}) do
    infinite_point(a, b)
  end

  # adding 2 points all other cases
  def add(%Pointi{x: x1, y: y1, a: a, b: b}, %Pointi{x: x2, y: y2, a: a, b: b}) do
    slope = (y2 - y1) / (x2 - x1)
    x3 = :math.pow(slope, 2) - x1 - x2
    y3 = slope * (x1 - x3) - y1

    Pointi.new(x3, y3, a, b)
  end

  # not yet implemented, as it is not used
  # def dot(%Pointi{} = ep, n), do: ...
  # def dot(n, %Pointi{} = ep), do: ...

  # Private utility functions

  def is_in_curve(x, y, a, b) do
    :math.pow(y, 2) == :math.pow(x, 3) + x * a + b
  end

  def infinite_point(a, b), do: %Pointi{x: nil, y: nil, a: a, b: b}
end
