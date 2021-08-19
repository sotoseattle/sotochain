defmodule Ledger.TxOut do
  alias Util

  defstruct amount: nil, script_key: nil

  def process_txout(tupo, 0), do: tupo

  def process_txout(tx, n) do
    {mess, txout} = parse_output(tx.meta)

    tx
    |> Map.put(:outputs, [txout | tx.outputs])
    |> Map.put(:meta, mess)
    |> process_txout(n - 1)
  end

  def parse_output(mess) do
    {mess, %__MODULE__{}}
    |> extract_amount()
    |> extract_script_key()
  end

  def extract_amount({<<amount::bytes-size(8), rest::binary>>, txout}),
    do: {rest, %{txout | amount: :binary.decode_unsigned(amount, :little)}}

  def extract_script_key({mess, txout}) do
    {script_size, mess} = Util.parse_varint(mess)
    <<sig::binary-size(script_size), rest::binary>> = mess
    {rest, %{txout | script_key: :binary.encode_hex(sig)}}
  end

  def serialize(txout) do
    sig_varint =
      String.length(txout.script_key)
      |> Integer.floor_div(2)
      |> Integer.to_string(16)

    Util.int_2_litt_hex(txout.amount, 8) <> sig_varint <> txout.script_key
  end
end
