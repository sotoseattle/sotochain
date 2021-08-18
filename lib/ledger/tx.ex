defmodule Ledger.Tx do
  alias Util
  alias Ledger.Tx
  alias Ledger.TxIn
  alias Ledger.TxOut

  defstruct version: nil,
            inputs: [],
            outputs: [],
            locktime: nil,
            net: :main,
            meta: nil

  @doc "Human readable hash of the transaction. Block explorers search by it."
  def id(tx) do
    :crypto.hash(:sha256, tx) |> :binary.encode_hex()
  end

  def parse(tx_hex) do
    %Tx{}
    |> Map.put(:meta, :binary.decode_hex(tx_hex))
    |> extract_version()
    |> process_inputs()
    |> process_outputs()
    |> extract_locktime()
    |> verify_count()
  end

  def extract_version(%{meta: <<version::32-little, rest::binary>>} = tx) do
    %{tx | version: version, meta: rest}
  end

  def process_inputs(tx) do
    {n_inputs, mess} = Util.parse_varint(tx.meta)
    TxIn.process_txin(%{tx | meta: mess}, n_inputs)
  end

  def process_outputs(tx) do
    {n_outputs, mess} = Util.parse_varint(tx.meta)
    TxOut.process_txout(%{tx | meta: mess}, n_outputs)
  end

  def extract_locktime(%{meta: <<locktime::binary-size(4), rest::binary>>} = tx) do
    %{tx | locktime: :binary.decode_unsigned(locktime, :little), meta: rest}
  end

  def verify_count(%{meta: ""} = tx), do: tx
  def verify_count(_), do: {:error, "transaction bytes remain unparsed"}

  def hash(tx), do: :crypto.hash(:sha256, serialize(tx))

  # to be implemented later
  def serialize(tx), do: tx

  # defimpl Inspect, for: Tx do
  #   def inspect(tx, _opts) do
  #     """
  #     Inputs: #{tx.inputs |> IO.inspect()}
  #     Outputs: #{tx.outputs |> IO.inspect()}
  #     Version: #{tx.version}
  #     Locktime: #{tx.locktime}
  #     Network: #{tx.net}
  #     """
  #   end
  # end
end
