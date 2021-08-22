defmodule Wallet do
  alias Ec.Point256
  alias Ec.Point
  alias Ec.Signature
  alias Util

  defstruct private_key: nil, public_key: nil

  @type t(private_key, public_key) :: %Wallet{private_key: private_key, public_key: public_key}
  @type t :: %Wallet{private_key: integer, public_key: Point.t()}

  @g Point256.spc256k1_g()
  @n Point256.spc256k1_n()

  @doc """
  A wallet holds a pair of keys (secret/private and public key)
  The private key is just a big integer, the public one is a point 256
  derived from the private one and the SPC256 EC plus finite field used
  """
  @spec new(String.t()) :: Wallet.t()
  def new(secret) when is_binary(secret) do
    with z <- hash_n(secret),
         k <- Integer.mod(z, @n),
         p <- Point.dot(k, @g) do
      %Wallet{}
      |> Map.put(:private_key, k)
      |> Map.put(:public_key, p)
    end
  end

  @spec new(pos_integer) :: Wallet.t()
  def new(secret_n) when is_integer(secret_n) and secret_n > 0 do
    with k <- Integer.mod(secret_n, @n),
         p <- Point.dot(k, @g) do
      %Wallet{}
      |> Map.put(:private_key, k)
      |> Map.put(:public_key, p)
    end
  end

  @doc "get public key serialized with compression"
  @spec pub_key_hex(Wallet.t()) :: String.t()
  def pub_key_hex(%Wallet{public_key: p}), do: Ec.Point256.serialize(p)

  @doc """
  Sign a message with a wallet and receive the hashed message in hex format, 
  plus the signature also serialized in hex format.
  """
  @spec sign(String.t(), Wallet.t()) :: %{hash: String.t(), signature: String.t()}
  def sign(message, %Wallet{} = wallet) when is_binary(message) do
    with z <- hash_n(message),
         k <- wallet.private_key,
         s <- Signature.sign(z, k),
         sh <- Signature.serialize(s),
         zh <- Util.int_2_hex_big(z) do
      %{hash: zh, signature: sh}
    end
  end

  @spec sign(integer, Wallet.t()) :: %{hash: String.t(), signature: String.t()}
  def sign(number_z, %Wallet{} = wallet) when is_integer(number_z) do
    with k <- wallet.private_key,
         s <- Signature.sign(number_z, k),
         sh <- Signature.serialize(s),
         zh <- Util.int_2_hex_big(number_z) do
      %{hash: zh, signature: sh}
    end
  end

  @doc """
  Verify a digital signature
  """
  @spec verify(String.t(), String.t(), String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def verify(hash_hex, sign_hex, key_hex)
      when is_binary(hash_hex) and
             is_binary(sign_hex) and
             is_binary(key_hex) do
    with n <- Util.hex_2_int(hash_hex),
         s <- Signature.parse(sign_hex),
         p <- Point256.parse(key_hex) do
      Signature.verify(n, s, p)
    end
  end

  @spec hash_n(String.t()) :: integer
  def hash_n(str) do
    :crypto.hash(:sha256, str) |> Base.encode16() |> Util.hex_2_int()
  end

  @doc "Serialization of private key according to WIF"
  def serial_private(private_key, sec \\ :compr, net \\ :main)

  @spec serial_private(integer, atom(), atom()) :: String.t()
  def serial_private(private_key, sec, net) when is_integer(private_key) do
    private_key
    |> Util.int_2_bin()
    |> add_prefix(net)
    |> add_suffix(sec)
    |> Util.add_checksum()
    |> Util.encode_base58()
  end

  @spec serial_private(String.t(), atom(), atom()) :: String.t()
  def serial_private(hex_key, sec, net) when is_binary(hex_key) do
    hex_key
    |> :binary.decode_hex()
    |> add_prefix(net)
    |> add_suffix(sec)
    |> Util.add_checksum()
    |> Util.encode_base58()
  end

  defp add_prefix(bin, :main), do: <<128::integer, bin::binary>>
  defp add_prefix(bin, :test), do: <<239::integer, bin::binary>>
  defp add_suffix(bin, :compr), do: <<bin::binary, 1::integer>>
  defp add_suffix(bin, _), do: bin

  @doc "Obtain the wallet' address based on its public key"
  @spec address(Wallet.t(), atom(), atom()) :: String.t()
  def address(%Wallet{} = wallet, compr \\ :compr, net \\ :main) do
    Point256.address(wallet.public_key, compr, net)
  end
end
