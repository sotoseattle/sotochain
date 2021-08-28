defmodule Ledger.TxIn do
  alias Util
  alias Ledger.TxIn

  defstruct prev_tx: nil, prev_idx: nil, script_sig: nil, seq: nil, meta: nil

  @type t(prev_tx, prev_idx, script_sig, seq) :: %TxIn{
          prev_tx: prev_tx,
          prev_idx: prev_idx,
          script_sig: script_sig,
          seq: seq
        }
  @type t :: %TxIn{
          prev_tx: String.t(),
          prev_idx: integer,
          script_sig: String.t(),
          seq: String.t()
        }

  @spec process_txin(Tx.t(), integer) :: Tx.t()
  def process_txin(tupo, 0), do: tupo

  def process_txin(tx, n) do
    {mess, txin} = parse_input(tx.meta)

    tx
    |> Map.put(:inputs, [txin | tx.inputs])
    |> Map.put(:meta, mess)
    |> process_txin(n - 1)
  end

  @spec parse_input(binary) :: {binary, TxIn.t()}
  def parse_input(mess) do
    {mess, %TxIn{}}
    |> extract_previous_tx_hash()
    |> extract_previous_tx_indx()
    |> extract_script_sig()
    |> extract_sequence()
  end

  defp extract_previous_tx_hash({<<hash::bytes-size(32), rest::binary>>, txin}) do
    {rest, %{txin | prev_tx: :binary.encode_hex(hash)}}
  end

  defp extract_previous_tx_indx({<<idx::32-little, rest::binary>>, txin}),
    do: {rest, %{txin | prev_idx: idx}}

  defp extract_script_sig({mess, txin}) do
    {script_size, mess} = Util.parse_varint(mess)
    <<sig::bytes-size(script_size), rest::binary>> = mess
    {rest, %{txin | script_sig: :binary.encode_hex(sig)}}
  end

  defp extract_sequence({<<seq::binary-size(4), rest::binary>>, txin}),
    do: {rest, %{txin | seq: :binary.encode_hex(seq)}}

  @spec serialize(TxIn.t()) :: String.t()
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

  def serialize_2(txin) do
    txin.prev_tx <>
      Util.int_2_litt_hex(txin.prev_idx, 4) <>
      txin.meta.script_key <>
      txin.seq
  end
end
