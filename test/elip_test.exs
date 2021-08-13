defmodule ElipTest do
  use ExUnit.Case

  doctest Elip

  test "eliptic curve points over a finite field" do
    prime = 223
    a = Fe.new(0, prime)
    b = Fe.new(7, prime)

    valid_points = [{192, 105}, {17, 56}, {1, 193}]
    invalid_ones = [{200, 119}, {42, 99}]

    valid_points
    |> Enum.map(&map_to_fe(&1, prime))
    |> Enum.map(&map_to_ep(&1, a, b))
    |> Enum.each(&assert(%Elip{} = &1))

    invalid_ones
    |> Enum.map(&map_to_fe(&1, prime))
    |> Enum.map(&map_to_ep(&1, a, b))
    |> Enum.each(&assert({:error, _} = &1))
  end

  test "addition of Elip on Fe" do
    prime = 223
    a = Fe.new(0, prime)
    b = Fe.new(7, prime)

    p1 = Elip.new(Fe.new(170, prime), Fe.new(142, prime), a, b)
    p2 = Elip.new(Fe.new(60, prime), Fe.new(139, prime), a, b)
    p3 = Elip.new(Fe.new(47, prime), Fe.new(71, prime), a, b)
    p4 = Elip.new(Fe.new(17, prime), Fe.new(56, prime), a, b)
    p5 = Elip.new(Fe.new(143, prime), Fe.new(98, prime), a, b)
    p6 = Elip.new(Fe.new(76, prime), Fe.new(66, prime), a, b)

    assert Elip.new(Fe.new(220, prime), Fe.new(181, prime), a, b) == Elip.add(p1, p2)
    assert Elip.new(Fe.new(215, prime), Fe.new(68, prime), a, b) == Elip.add(p3, p4)
    assert Elip.new(Fe.new(47, prime), Fe.new(71, prime), a, b) == Elip.add(p5, p6)
  end

  test "dot or scalar product on Elip of Fes" do
    prime = 223
    a = Fe.new(0, prime)
    b = Fe.new(7, prime)
    p1 = Elip.new(Fe.new(47, prime), Fe.new(71, prime), a, b)

    assert Elip.dot(p1, 2) == Elip.new(Fe.new(36, prime), Fe.new(111, prime), a, b)
    assert Elip.dot(p1, 20) == Elip.new(Fe.new(47, prime), Fe.new(152, prime), a, b)
  end

  test "in the real deal" do
    {gx, ""} =
      "79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798"
      |> Integer.parse(16)

    {gy, ""} =
      "483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8"
      |> Integer.parse(16)

    p = Integer.pow(2, 256) - Integer.pow(2, 32) - 977

    x = Fe.new(gx, p)
    y = Fe.new(gy, p)
    a = Fe.new(0, p)
    b = Fe.new(7, p)

    {n, ""} =
      "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141"
      |> Integer.parse(16)

    assert g = Elip.new(x, y, a, b)
    assert Elip.dot(g, n) == Elip.infinite_point(a, b)
  end

  defp map_to_fe({x, y}, prime), do: {Fe.new(x, prime), Fe.new(y, prime)}
  defp map_to_ep({x, y}, a, b), do: Elip.new(x, y, a, b)
end
