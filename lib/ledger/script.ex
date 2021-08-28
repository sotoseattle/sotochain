defmodule Ledger.Script do
  alias Util
  alias Ec.Point256
  alias Ec.Signature

  @doc """
  Parsing a hex string from script_sig or script_key
  The result is a stack of elements (binaries) and operation commands (int)
  """
  @spec parse(String.t()) :: list(integer | String.t())
  def parse(hexo) when is_binary(hexo), do: :binary.decode_hex(hexo) |> parse([])

  defp parse(<<>>, listo), do: listo |> Enum.reverse()

  defp parse(<<n::integer, e::binary-size(n), rest::binary>>, listo) when n < 76 do
    parse(rest, [:binary.encode_hex(e) | listo])
  end

  defp parse(<<76::integer, n::integer-size(1), e::binary-size(n), rest::binary>>, listo) do
    parse(rest, [:binary.encode_hex(e) | listo])
  end

  defp parse(<<77::integer, n::integer-size(2), e::binary-size(n), rest::binary>>, listo) do
    parse(rest, [:binary.encode_hex(e) | listo])
  end

  defp parse(<<78::integer, n::integer-size(4), e::binary-size(n), rest::binary>>, listo) do
    parse(rest, [:binary.encode_hex(e) | listo])
  end

  defp parse(<<n::integer, rest::binary>>, listo) when n in 82..96 do
    parse(rest, [n - 80 | listo])
  end

  defp parse(<<cmd::integer, rest::binary>>, listo) do
    parse(rest, [ops_ref(cmd) | listo])
  end

  def format_stack([], acc), do: acc |> Enum.reverse()

  def format_stack([h | t], acc) when is_function(h) do
    format_stack(t, [format_name(h) | acc])
  end

  def format_stack([h | t], acc), do: format_stack(t, [h | acc])

  def ops_ref(code) do
    %{
      87 => &op_equal/1,
      105 => &op_evaluate/1,
      110 => &op_2dup/1,
      118 => &op_dup/1,
      124 => &op_swap/1,
      135 => &op_equal/1,
      145 => &op_not/1,
      147 => &op_add/1,
      149 => &op_mul/1,
      167 => &op_sha1/1,
      169 => &op_hash160/1,
      170 => &op_hash256/1,
      172 => &op_checksig/1
    }
    |> Map.get(code, &op_no_idea_so_id/1)
  end

  # this is terrible, I know...
  defp format_name(fo) do
    fo
    |> Function.info()
    |> Enum.at(6)
    |> elem(1)
    |> Atom.to_string()
    |> String.replace(~r/[-fun.|\/1-]/, "")
    |> String.upcase()
    |> String.to_atom()
  end

  def combine(stacko, stacka), do: stacko ++ stacka

  def evaluate(stacko, acc \\ [])
  def evaluate([], acc), do: acc == [1]
  def evaluate([h | t], acc), do: evaluate(t, apply_op(h, acc))

  def apply_op(false, _), do: false
  def apply_op(fo, listo) when is_function(fo), do: fo.(listo)
  def apply_op(e, listo), do: [e | listo]

  def op_no_idea_so_id(anything), do: anything

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

  def op_sha1([h | t]), do: [:crypto.hash(:sha, h) | t]
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
end
