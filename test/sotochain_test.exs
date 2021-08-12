defmodule SotochainTest do
  use ExUnit.Case
  doctest Sotochain

  test "greets the world" do
    assert Sotochain.hello() == :world
  end
end
