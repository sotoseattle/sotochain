defmodule FastoTest do
  use ExUnit.Case

  test "equality of field elements" do
    k = 223
    x = Fe.new(47, k)
    y = Fe.new(71, k)
    a = Fe.new(0, k)
    b = Fe.new(7, k)

    ep = Elip.new(x, y, a, b)

    assert Fasto.doto(ep, 1) == ep
    assert Fasto.doto(ep, 2) == Elip.new(Fe.new(36, k), Fe.new(111, k), a, b)
    assert Fasto.doto(ep, 3) == Elip.new(Fe.new(15, k), Fe.new(137, k), a, b)
    assert Fasto.doto(ep, 20) == Elip.new(Fe.new(47, k), Fe.new(152, k), a, b)
    assert Fasto.doto(ep, 21) == Elip.infinite_point(a, b)
  end
end
