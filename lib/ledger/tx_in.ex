defmodule Ledger.TxIn do
  alias Util
  alias Ledger.TxIn

  defstruct prev_tx: nil, prev_idx: nil, script_sig: nil, seq: nil, meta: nil, sig_hash: nil

  @type t(prev_tx, prev_idx, script_sig, seq, meta, sig_hash) :: %TxIn{
          prev_tx: prev_tx,
          prev_idx: prev_idx,
          script_sig: script_sig,
          seq: seq,
          meta: meta,
          sig_hash: sig_hash
        }
  @type t :: %TxIn{
          prev_tx: String.t(),
          prev_idx: integer,
          script_sig: String.t(),
          seq: String.t(),
          meta: binary,
          sig_hash: binary
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

  def sig_hash(txin, raw_hex) do
    to_replace = Util.prepend_size(txin.script_sig)
    prev_pbkey = Util.prepend_size(txin.meta.script_key)

    z =
      raw_hex
      |> String.replace(to_replace, prev_pbkey)
      |> Kernel.<>("01000000")
      |> :binary.decode_hex()
      |> Util.hash256_2x()
      |> :binary.decode_unsigned(:big)

    %{txin | sig_hash: z}
  end
end
