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
    |> verify_count()
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

  defp verify_count(%{meta: ""} = tx), do: tx
  defp verify_count(_), do: {:error, "transaction bytes remain unparsed"}

  # def hash(tx), do: :crypto.hash(:sha256, serialize(tx))

  # def fetch(%TxIn{} = tx, net) do
  #   txn = tx.prev_tx
  #   url = fetch_url(net)
  #   {:ok, %{body: raw}} = HTTPoison.get(url <> txn <> "/hex")
  #   raw
  # end
  #
  # defp fetch_url(:main), do: "https://blockstream.info/testnet/api/tx/"
  # defp fetch_url(:test), do: "https://blockstream.info/testnet/api/tx/"
end
