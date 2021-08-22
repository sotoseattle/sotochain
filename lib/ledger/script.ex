defmodule Ledger.Script do
  alias Util
  alias Ec.Point256
  alias Ec.Signature

  @spec generate_script_stack(binary) :: list(integer | String.t())
  def generate_script_stack(scripto_bin) do
    scripto_bin
    |> :binary.decode_hex()
    |> parse([])
  end

  @doc "Parsing a hex string from script_sig or script_key"
  @spec parse(String.t()) :: list(integer | String.t())
  def parse(hexo) when is_binary(hexo), do: :binary.decode_hex(hexo) |> parse([])

  @spec parse(<<>>, list(integer | String.t())) :: list(integer | String.t())
  def parse(<<>>, stacko), do: stacko |> Enum.reverse()

  def parse(<<n, rest::binary>>, stacko) when n > 0 and n <= 75 do
    # IO.puts("... #{n} => getting ele: #{n}")
    parse(rest, [n | stacko])
  end

  def parse(<<n, rest::binary>>, stacko) when n >= 82 and n <= 96 do
    # IO.puts("... #{n} => pushing ele: #{n}")
    parse(rest, [n - 80 | stacko])
  end

  def parse(<<"4C"::binary, n::little-size(1), e::bytes-size(n), rest::binary>>, stacko) do
    # IO.puts("... 76 => getting #{n} bytes => getting ele: #{:binary.encode_hex(e)}")
    parse(rest, [e | stacko])
  end

  def parse(<<"4D"::binary, n::little-size(2), e::bytes-size(n), rest::binary>>, stacko) do
    # IO.puts("... 77 => getting #{n} bytes => getting ele: #{:binary.encode_hex(e)}")
    parse(rest, [e | stacko])
  end

  def parse(<<cmd, rest::binary>>, stacko) do
    # IO.puts("... getting command: #{cmd}")
    parse(rest, [cmd | stacko])
  end

  def combine(stacko, stacka), do: stacko ++ stacka

  def evaluate(stacko, acc \\ [])
  def evaluate([], acc), do: acc == [1]
  def evaluate([h | t], acc), do: evaluate(t, apply_op(h, acc))

  def op_evaluate([1 | t]), do: t
  def op_evaluate(_), do: false

  def op_2dup([a, b | t]), do: [a, b, a, b | t]
  def op_dup([h | _] = stack), do: [h | stack]

  def op_add([a, b | t]), do: [a + b | t]
  def op_mul([a, b | t]), do: [a * b | t]

  def op_swap([a, b | t]), do: [b, a | t]

  def op_equal([a, a | t]), do: [1 | t]
  def op_equal([_, _ | t]), do: [0 | t]

  def op_not([1 | t]), do: [0 | t]
  def op_not([0 | t]), do: [1 | t]
  def op_not([_ | t]), do: [0 | t]

  def op_sha1([h | t]) do
    [:crypto.hash(:sha, h) | t]
  end

  def op_sha1(_), do: false

  def op_hash256([h | t]), do: [:crypto.hash(:sha256, h) | t]
  def op_hash256(_), do: false

  def op_hash160([h | t]), do: [Util.hash160(h) | t]
  def op_hash160(_), do: false

  def op_checksig([a, b | t], z) do
    with key <- Point256.parse(b),
         sig <- Signature.parse(a),
         {:ok, _} <- Signature.verify(z, sig, key) do
      [1 | t]
    else
      _ -> [0 | t]
    end
  end

  def op_checksig(_), do: false

  defp apply_op(false, _), do: false
  defp apply_op(76, acc), do: op_dup(acc)
  defp apply_op(87, acc), do: op_equal(acc)
  defp apply_op(105, acc), do: op_evaluate(acc)
  defp apply_op(110, acc), do: op_2dup(acc)
  defp apply_op(118, acc), do: op_dup(acc)
  defp apply_op(124, acc), do: op_swap(acc)
  defp apply_op(135, acc), do: op_equal(acc)
  defp apply_op(145, acc), do: op_not(acc)
  defp apply_op(147, acc), do: op_add(acc)
  defp apply_op(149, acc), do: op_mul(acc)
  defp apply_op(167, acc), do: op_sha1(acc)
  defp apply_op(169, acc), do: op_hash160(acc)
  defp apply_op(170, acc), do: op_hash256(acc)
  # defp apply_op(172, acc), do: op_checksig(acc, "hola")
  defp apply_op(ele, acc), do: [ele | acc]
end
