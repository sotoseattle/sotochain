defmodule Ledger.TxIn do
  alias Util

  defstruct prev_tx: nil, prev_idx: nil, script_sig: nil, seq: nil

  def process_txin(tupo, 0), do: tupo

  def process_txin(tx, n) do
    {mess, txin} = parse_input(tx.meta)

    tx
    |> Map.put(:inputs, [txin | tx.inputs])
    |> Map.put(:meta, mess)
    |> process_txin(n - 1)
  end

  def parse_input(mess) do
    {mess, %__MODULE__{}}
    |> extract_previous_tx_hash()
    |> extract_previous_tx_indx()
    |> extract_script_sig()
    |> extract_sequence()
  end

  def extract_previous_tx_hash({<<hash::bytes-size(32), rest::binary>>, txin}) do
    {rest, %{txin | prev_tx: :binary.encode_hex(hash)}}
  end

  def extract_previous_tx_indx({<<idx::32-little, rest::binary>>, txin}),
    do: {rest, %{txin | prev_idx: idx}}

  def extract_script_sig({mess, txin}) do
    {script_size, mess} = Util.parse_varint(mess)
    <<sig::bytes-size(script_size), rest::binary>> = mess
    {rest, %{txin | script_sig: :binary.encode_hex(sig)}}
  end

  def extract_sequence({<<seq::binary-size(4), rest::binary>>, txin}),
    do: {rest, %{txin | seq: :binary.encode_hex(seq)}}

  def serialize(txin) do
    sig_varint =
      String.length(txin.script_sig)
      |> Integer.floor_div(2)
      |> Integer.to_string(16)

    txin.prev_tx <>
      Util.int_2_litt_hex(txin.prev_idx, 4) <>
      sig_varint <>
      txin.script_sig <>
      txin.seq
  end
end
