defmodule PointTest do
  use ExUnit.Case
  alias Ec.Fifi
  alias Ec.Point
  alias Ec.Fasto

  doctest Ec.Point

  test "eliptic curve points over a finite field" do
    prime = 223
    a = Fifi.new(0, prime)
    b = Fifi.new(7, prime)

    valid_points = [{192, 105}, {17, 56}, {1, 193}]
    invalid_ones = [{200, 119}, {42, 99}]

    valid_points
    |> Enum.map(&map_to_fe(&1, prime))
    |> Enum.map(&map_to_ep(&1, a, b))
    |> Enum.each(&assert(%Point{} = &1))

    invalid_ones
    |> Enum.map(&map_to_fe(&1, prime))
    |> Enum.map(&map_to_ep(&1, a, b))
    |> Enum.each(&assert({:error, _} = &1))
  end

  test "addition of Point on Fifi" do
    prime = 223
    a = Fifi.new(0, prime)
    b = Fifi.new(7, prime)

    p1 = Point.new(Fifi.new(170, prime), Fifi.new(142, prime), a, b)
    p2 = Point.new(Fifi.new(60, prime), Fifi.new(139, prime), a, b)
    p3 = Point.new(Fifi.new(47, prime), Fifi.new(71, prime), a, b)
    p4 = Point.new(Fifi.new(17, prime), Fifi.new(56, prime), a, b)
    p5 = Point.new(Fifi.new(143, prime), Fifi.new(98, prime), a, b)
    p6 = Point.new(Fifi.new(76, prime), Fifi.new(66, prime), a, b)

    assert Point.new(Fifi.new(220, prime), Fifi.new(181, prime), a, b) == Point.add(p1, p2)
    assert Point.new(Fifi.new(215, prime), Fifi.new(68, prime), a, b) == Point.add(p3, p4)
    assert Point.new(Fifi.new(47, prime), Fifi.new(71, prime), a, b) == Point.add(p5, p6)
  end

  test "dot or scalar product on Point of Fifis" do
    k = 223
    x = Fifi.new(47, k)
    y = Fifi.new(71, k)
    a = Fifi.new(0, k)
    b = Fifi.new(7, k)

    ep = Point.new(x, y, a, b)

    assert Fasto.doto(ep, 1) == ep
    assert Fasto.doto(ep, 2) == Point.new(Fifi.new(36, k), Fifi.new(111, k), a, b)
    assert Fasto.doto(ep, 3) == Point.new(Fifi.new(15, k), Fifi.new(137, k), a, b)
    assert Fasto.doto(ep, 20) == Point.new(Fifi.new(47, k), Fifi.new(152, k), a, b)
    assert Fasto.doto(ep, 21) == Point.infinite_point(a, b)
  end

  test "in the real deal" do
    {gx, ""} =
      "79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798"
      |> Integer.parse(16)

    {gy, ""} =
      "483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8"
      |> Integer.parse(16)

    p = Integer.pow(2, 256) - Integer.pow(2, 32) - 977

    x = Fifi.new(gx, p)
    y = Fifi.new(gy, p)
    a = Fifi.new(0, p)
    b = Fifi.new(7, p)

    {n, ""} =
      "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141"
      |> Integer.parse(16)

    assert g = Point.new(x, y, a, b)
    assert Point.dot(g, n) == Point.infinite_point(a, b)
  end

  defp map_to_fe({x, y}, prime), do: {Fifi.new(x, prime), Fifi.new(y, prime)}
  defp map_to_ep({x, y}, a, b), do: Point.new(x, y, a, b)
end
