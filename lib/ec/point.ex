defmodule Ec.Point do
  alias Ec.Fifi
  alias Ec.Point
  alias Util

  @moduledoc "Point in eliptic curve projected unto finite field"

  defstruct x: nil, y: nil, a: nil, b: nil

  @type t(x, y, a, b) :: %Point{x: x, y: y, a: a, b: b}
  @type t :: %Point{x: %Fifi{}, y: %Fifi{}, a: %Fifi{}, b: %Fifi{}}

  @doc """
  A point {x, y} in an eliptic curve defined by params {a, b}
  iex> x = Fifi.new(192, 223)
  iex> y = Fifi.new(105, 223)
  iex> a = Fifi.new(0, 223)
  iex> b = Fifi.new(7, 223)
  iex> Point.new(x, y, a, b)
  %Point{
  a: %Fifi{n: 0, k: 223},
  b: %Fifi{n: 7, k: 223},
  x: %Fifi{n: 192, k: 223},
  y: %Fifi{n: 105, k: 223}
  }
  """
  @spec new(nil, nil, Fifi.t(), Fifi.t()) :: Point.t()
  def new(nil, nil, a, b), do: %Point{x: nil, y: nil, a: a, b: b}

  @spec new(Fifi.t(), Fifi.t(), Fifi.t(), Fifi.t()) :: Point.t() | {:error, String.t()}
  def new(x, y, a, b) do
    if is_in_curve(x, y, a, b) do
      %Point{x: x, y: y, a: a, b: b}
    else
      {:error, "point {x, y} ∌ y^2 = x^3 + ax + b"}
    end
  end

  @doc """
  Addition by point at infinity (de facto zero) equals the point
  Addition of two points with same x means the sum is at infinity
  If the two points are equals, then they are at the tangent to the curve
  and we can find the slope and intersection of the 3rd point
  If the tangent is the vertical (at y == 0) the intersect is infinity
  In any other case, given two points, the sum can be derived from the
  intersection of the line they form and the eliptic curve
  """

  # add p1 and ∞ => p1
  @spec add(Point.t(), Point.t()) :: Point.t()
  def add(%Point{x: nil, y: nil, a: a, b: b}, %Point{a: a, b: b} = p2), do: p2
  def add(%Point{a: a, b: b} = p1, %Point{x: nil, y: nil, a: a, b: b}), do: p1

  # adding a tangent at y == 0 => ∞
  def add(%Point{y: 0, a: a, b: b} = p1, p1), do: infinite_point(a, b)

  # adding the same point twice => tangent
  def add(%Point{x: x, y: y, a: a, b: b} = p1, p1) do
    k = x.k
    s1 = (Util.powo(x.n, 2, k) * 3 + a.n) |> Integer.mod(k)
    s2 = Util.powo(2 * y.n, k - 2, k)
    slope = (s1 * s2) |> Integer.mod(k)

    xo = (Integer.pow(slope, 2) - 2 * x.n) |> Integer.mod(k)
    yo = ((x.n - xo) * slope - y.n) |> Integer.mod(k)

    x3 = Fifi.new(xo, k)
    y3 = Fifi.new(yo, k)

    Point.new(x3, y3, a, b)
  end

  # adding 2 point with same x => vertical line => ∞
  def add(%Point{x: x, a: a, b: b}, %Point{x: x, a: a, b: b}) do
    infinite_point(a, b)
  end

  # adding 2 points all other cases
  def add(%Point{x: x1, y: y1, a: a, b: b}, %Point{x: x2, y: y2, a: a, b: b}) do
    k = x1.k
    s1 = y2.n - y1.n
    s2 = Util.powo(x2.n - x1.n, k - 2, k)
    slope = (s1 * s2) |> Integer.mod(k)

    xo = (Integer.pow(slope, 2) - x1.n - x2.n) |> Integer.mod(k)
    yo = ((x1.n - xo) * slope - y1.n) |> Integer.mod(k)

    x3 = Fifi.new(xo, k)
    y3 = Fifi.new(yo, k)

    Point.new(x3, y3, a, b)
  end

  @spec dot(Point.t(), integer) :: Point.t()
  def dot(%Point{} = ep, n), do: Util.doto(ep, n)

  @spec dot(integer, Point.t()) :: Point.t()
  def dot(n, %Point{} = ep), do: Util.doto(ep, n)

  # Utility functions

  @spec is_in_curve(Fifi.t(), Fifi.t(), Fifi.t(), Fifi.t()) :: boolean
  def is_in_curve(x, y, a, b) do
    Integer.pow(y.n, 2) |> Integer.mod(y.k) ==
      (Integer.pow(x.n, 3) + x.n * a.n + b.n) |> Integer.mod(x.k)
  end

  def infinite_point(a, b), do: %Point{x: nil, y: nil, a: a, b: b}

  defimpl Inspect, for: Point do
    def inspect(p, _opts) do
      """
      Point coordinates on Eliptic Curve:
        x: #{p.x.n}
        y: #{p.y.n}
      Curve coefficients:
        a: #{p.a.n}
        b: #{p.b.n}
      Finite Field:
        k: #{p.x.k}
      """
    end
  end

  defimpl String.Chars, for: Point do
    def to_string(p) do
      "PoEC: {#{peek(p.x.n)}, #{peek(p.y.n)}} on EC (#{p.a.n}, #{p.b.n}) with prime: #{peek(p.x.k)}"
    end

    def peek(chocho) when chocho > 1_000_000 do
      str = "#{chocho}"
      String.slice(str, 0, 3) <> ".." <> String.slice(str, -2, 2)
    end
  end
end
