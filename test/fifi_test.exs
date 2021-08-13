defmodule FifiTest do
  use ExUnit.Case
  alias Ec.Fifi

  test "equality of field elements" do
    a = Fifi.new(7, 13)
    b = Fifi.new(6, 13)

    refute a == b
    assert a != b
    refute b != %Fifi{n: 6, k: 13}
  end

  test "addiFion" do
    assert Fifi.new(2, 31) |> Fifi.addf(Fifi.new(15, 31)) == Fifi.new(17, 31)
    assert Fifi.new(17, 31) |> Fifi.addf(Fifi.new(21, 31)) == Fifi.new(7, 31)
  end

  test "negatiFifi" do
    assert Fifi.new(9, 19) |> Fifi.negf() == %Fifi{k: 19, n: 10}
  end

  test "substracFion" do
    assert Fifi.new(29, 31) |> Fifi.subf(Fifi.new(4, 31)) == Fifi.new(25, 31)
    assert Fifi.new(15, 31) |> Fifi.subf(Fifi.new(30, 31)) == Fifi.new(16, 31)
  end

  test "produFt" do
    assert Fifi.new(24, 31) |> Fifi.prodf(Fifi.new(19, 31)) == Fifi.new(22, 31)
    assert Fifi.new(5, 19) |> Fifi.prodf(Fifi.new(3, 19)) == Fifi.new(15, 19)
    assert Fifi.new(8, 19) |> Fifi.prodf(Fifi.new(17, 19)) == Fifi.new(3, 19)
  end

  test "exfonenFiaFion" do
    assert Fifi.new(17, 31) |> Fifi.expf(3) == Fifi.new(15, 31)
    assert Fifi.new(5, 31) |> Fifi.expf(5) |> Fifi.prodf(Fifi.new(18, 31)) == Fifi.new(16, 31)
    assert Fifi.new(7, 19) |> Fifi.expf(3) == Fifi.new(1, 19)
    assert Fifi.new(9, 19) |> Fifi.expf(12) == Fifi.new(7, 19)
  end

  test "diFision" do
    assert Fifi.divf(Fifi.new(3, 31), Fifi.new(24, 31)) == Fifi.new(4, 31)
    assert Fifi.new(2, 19) |> Fifi.divf(Fifi.new(7, 19)) == Fifi.new(3, 19)
  end

  test "negative exfonenFiaFion" do
    a = Fifi.new(7, 13)
    b = Fifi.new(8, 13)
    assert Fifi.expf(a, -3) == b
  end
end
