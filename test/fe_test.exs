defmodule FeTest do
  use ExUnit.Case

  test "equality of field elements" do
    a = Fe.new(7, 13)
    b = Fe.new(6, 13)

    refute a == b
    assert Fe.ne(a, b)
    refute Fe.ne(b, %Fe{n: 6, k: 13})
  end

  test "addiFion" do
    assert Fe.new(2, 31) |> Fe.addf(Fe.new(15, 31)) == Fe.new(17, 31)
    assert Fe.new(17, 31) |> Fe.addf(Fe.new(21, 31)) == Fe.new(7, 31)
  end

  test "negatiFe" do
    assert Fe.new(9, 19) |> Fe.negf() == %Fe{k: 19, n: 10}
  end

  test "substracFion" do
    assert Fe.new(29, 31) |> Fe.subf(Fe.new(4, 31)) == Fe.new(25, 31)
    assert Fe.new(15, 31) |> Fe.subf(Fe.new(30, 31)) == Fe.new(16, 31)
  end

  test "produFt" do
    assert Fe.new(24, 31) |> Fe.prodf(Fe.new(19, 31)) == Fe.new(22, 31)
    assert Fe.new(5, 19) |> Fe.prodf(Fe.new(3, 19)) == Fe.new(15, 19)
    assert Fe.new(8, 19) |> Fe.prodf(Fe.new(17, 19)) == Fe.new(3, 19)
  end

  test "exfonenFiaFion" do
    assert Fe.new(17, 31) |> Fe.expf(3) == Fe.new(15, 31)
    assert Fe.new(5, 31) |> Fe.expf(5) |> Fe.prodf(Fe.new(18, 31)) == Fe.new(16, 31)
    assert Fe.new(7, 19) |> Fe.expf(3) == Fe.new(1, 19)
    assert Fe.new(9, 19) |> Fe.expf(12) == Fe.new(7, 19)
  end

  test "diFision" do
    assert Fe.divf(Fe.new(3, 31), Fe.new(24, 31)) == Fe.new(4, 31)
    assert Fe.new(2, 19) |> Fe.divf(Fe.new(7, 19)) == Fe.new(3, 19)
  end

  test "negative exfonenFiaFion" do
    a = Fe.new(7, 13)
    b = Fe.new(8, 13)
    assert Fe.expf(a, -3) == b
  end
end
