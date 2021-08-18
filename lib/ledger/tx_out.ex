defmodule Ledger.TxOut do
  alias Util

  defstruct amount: nil, script_key: nil

  def process_txout(tupo, 0), do: tupo

  # tx_outs should be reversed!!!!!
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

  def extract_amount({<<amount::binary-size(8), rest::binary>>, txout}),
    do: {rest, %{txout | amount: :binary.decode_unsigned(amount, :little)}}

  def extract_script_key({mess, txout}) do
    {script_size, mess} = Util.parse_varint(mess)
    <<sig::binary-size(script_size), rest::binary>> = mess
    {rest, %{txout | script_key: :binary.encode_hex(sig)}}
  end
end
