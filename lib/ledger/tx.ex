defmodule Ledger.Tx do
  alias Util
  alias Ledger.Tx
  alias Ledger.TxIn
  alias Ledger.TxOut
  alias Ledger.Script
  alias Ec.Signature
  alias Ec.Point256

  defstruct version: nil,
            inputs: [],
            outputs: [],
            locktime: nil,
            net: :main,
            meta: nil

  @type t(version, inputs, outputs, locktime, net, meta) :: %Tx{
          version: version,
          inputs: inputs,
          outputs: outputs,
          locktime: locktime,
          net: net,
          meta: meta
        }
  @type t :: %Tx{
          version: integer,
          inputs: list(TxIn.t()),
          outputs: list(TxOut.t()),
          locktime: integer,
          net: atom,
          meta: binary
        }

  # def id(tx) do
  #   :crypto.hash(:sha256, tx) |> :binary.encode_hex()
  # end

  @doc """
  Given a hex string deserialize and rebuild the transaction
  """
  @spec parse(String.t()) :: Tx.t()
  def parse(tx_hex) do
    %Tx{}
    |> Map.put(:meta, :binary.decode_hex(tx_hex))
    |> extract_version()
    |> process_inputs()
    |> process_outputs()
    |> extract_locktime()
    |> reverse_lists()
    |> check_bytes()
  end

  @spec serialize(Tx.t()) :: String.t()
  def serialize(tx) do
    ins = Enum.reduce(tx.inputs, "", fn x, acc -> acc <> Ledger.TxIn.serialize(x) end)
    ous = Enum.reduce(tx.outputs, "", fn x, acc -> acc <> Ledger.TxOut.serialize(x) end)
    in_varint = <<length(tx.inputs)::integer>> |> :binary.encode_hex()
    out_varint = <<length(tx.outputs)::integer>> |> :binary.encode_hex()

    Util.int_2_litt_hex(tx.version, 4) <>
      in_varint <>
      ins <>
      out_varint <>
      ous <>
      Util.int_2_litt_hex(tx.locktime, 4)
  end

  defp extract_version(%{meta: <<version::32-little, rest::binary>>} = tx) do
    %{tx | version: version, meta: rest}
  end

  defp process_inputs(tx) do
    {n_inputs, mess} = Util.parse_varint(tx.meta)

    tx
    |> Map.put(:meta, mess)
    |> TxIn.process_txin(n_inputs)
  end

  defp process_outputs(tx) do
    {n_outputs, mess} = Util.parse_varint(tx.meta)

    tx
    |> Map.put(:meta, mess)
    |> TxOut.process_txout(n_outputs)
  end

  defp extract_locktime(%{meta: <<locktime::binary-size(4), rest::binary>>} = tx) do
    %{tx | locktime: :binary.decode_unsigned(locktime, :little), meta: rest}
  end

  defp reverse_lists(tx) do
    tx
    |> Map.put(:inputs, Enum.reverse(tx.inputs))
    |> Map.put(:outputs, Enum.reverse(tx.outputs))
  end

  defp check_bytes(%{meta: ""} = tx), do: tx
  defp check_bytes(_), do: {:error, "transaction bytes remain unparsed"}

  def compute_sig_hashes(tx) do
    raw_hex = Tx.serialize(tx)

    ins =
      tx.inputs
      |> Enum.map(&TxIn.sig_hash(&1, raw_hex))

    %{tx | inputs: ins}
  end

  def fee(tx) do
    sat_in = tx.inputs |> Enum.reduce(0, fn i, acc -> acc + i.meta.amount end)
    sat_ot = tx.outputs |> Enum.reduce(0, fn o, acc -> acc + o.amount end)
    sat_in - sat_ot
  end

  @doc """
  Validates that all input signatures check out. That means that it needs 
  to have all the prev outputs in the corresponding :meta of each input.
  It will compute the hash of the signature (script_sig) of each input
  and then verify it with the signature and pub key given in script_sig
  """
  def verify_inputs(tx) do
    tx = Tx.compute_sig_hashes(tx)

    check = tx.inputs |> Enum.map(&valid_signature?(&1)) |> Enum.all?()

    validate(tx, check)
  end

  def valid_signature?(txin) do
    [sig, key] = Script.parse(txin.script_sig)

    Signature.verify(
      txin.sig_hash,
      Signature.parse(sig),
      Point256.parse(key)
    )
    |> elem(0) == :ok
  end

  def validate(tx, true), do: {:ok, tx}
  def validate(_tx, false), do: {:error, "the sig hash of an input cannot be verified"}
end
