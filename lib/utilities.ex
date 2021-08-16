defmodule Utilities do
  @base_58_alphabet "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
                    |> String.graphemes()

  @doc """
  Like base 64 without number 0 and letters O, l, I (to avoid confussion)
  BEWARE: I am not prepending zeroes because I am converting from int !!!
  """
  def encode_base58(bin) when is_binary(bin) do
    {bin_n, zeroes_n} = leading_zeroes(bin, 0)

    hex58 =
      bin_n
      |> :binary.encode_hex()
      |> hex_2_int()
      |> num_base58()

    String.duplicate("1", zeroes_n) <> hex58
  end

  defp num_base58(num, acc \\ [])
  defp num_base58(0, acc), do: acc |> Enum.join()

  defp num_base58(num, acc) do
    num_base58(
      Integer.floor_div(num, 58),
      [Enum.at(@base_58_alphabet, Integer.mod(num, 58)) | acc]
    )
  end

  defp leading_zeroes(<<0>> <> hex, c), do: leading_zeroes(hex, c + 1)
  defp leading_zeroes(hex, c), do: {hex, c}

  def hash160(message) do
    :crypto.hash(:ripemd160, :crypto.hash(:sha256, message))
  end

  def int_2_hex_big(i) do
    i |> :binary.encode_unsigned(:big) |> :binary.encode_hex()
  end

  def hex_2_int(hex) do
    hex |> Integer.parse(16) |> elem(0)
  end
end
