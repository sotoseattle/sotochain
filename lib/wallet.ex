defmodule Wallet do
  alias Ec.Point256
  alias Ec.Point
  alias Ec.Signature

  defstruct private_key: nil, public_key: nil, g: nil, n: nil

  @defaulto "lalailo"
  @g Point256.spc256k1_g()
  @n Point256.spc256k1_n()

  def new(secret \\ @defaulto) when is_binary(secret) do
    e = hasho(secret) |> Integer.mod(@n)
    p = Point.dot(e, @g)
    %__MODULE__{private_key: e, public_key: p, g: @g, n: @n}
  end

  def sign(message, wallet) do
    message |> hasho() |> Signature.sign(wallet)
  end

  def verify(signature), do: Signature.verify(signature, @g, @n)

  def hasho(str) do
    :crypto.hash(:sha256, str) |> Base.encode16() |> Integer.parse(16) |> elem(0)
  end
end
