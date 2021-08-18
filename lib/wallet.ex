defmodule Wallet do
  alias Ec.Point256
  alias Ec.Point
  alias Ec.Signature
  alias Util

  defstruct private_key: nil, public_key: nil, g: nil, n: nil

  @g Point256.spc256k1_g()
  @n Point256.spc256k1_n()

  def new(secret) when is_binary(secret) do
    e = hasho(secret) |> Integer.mod(@n)
    p = Point.dot(e, @g)
    %__MODULE__{private_key: e, public_key: p, g: @g, n: @n}
  end

  def new(secret) when is_number(secret) do
    e = secret |> Integer.mod(@n)
    p = Point.dot(e, @g)
    %__MODULE__{private_key: e, public_key: p, g: @g, n: @n}
  end

  def sign(message, wallet) do
    message |> hasho() |> Signature.sign(wallet)
  end

  def verify(signature), do: Signature.verify(signature, @g, @n)

  def hasho(str) do
    :crypto.hash(:sha256, str) |> Base.encode16() |> Util.hex_2_int()
  end

  @doc "Serialization of private key according to WIF"
  def serial_private(private_key, sec \\ :compr, net \\ :main) do
    private_key
    |> Util.int_2_bin()
    |> add_prefix(net)
    |> add_suffix(sec)
    |> Util.add_checksum()
    |> Util.encode_base58()
  end

  @doc "Obtain a bitcoin address based on public key"
  def address(%Wallet{} = wallet, compr \\ :compr, net \\ :main) do
    Point256.address(wallet.public_key, compr, net)
  end

  defp add_prefix(bin, :main), do: <<128::integer, bin::binary>>
  defp add_prefix(bin, :test), do: <<239::integer, bin::binary>>
  defp add_suffix(bin, :compr), do: <<bin::binary, 1::integer>>
  defp add_suffix(bin, _), do: bin
end
