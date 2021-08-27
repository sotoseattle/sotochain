defmodule Ledger.Fetch do
  alias Ledger.Tx
  alias Ledger.TxOut

  def fetch(tx_id) do
    tx_id
    |> retrieve_tx_online()
    |> check_unspent_utxo()
    |> expand_inputs()
    |> check_fee()
  end

  def retrieve_tx_online(tx_hex) do
    with {:ok, raw} <- outside_query(tx_hex) do
      raw
      |> Tx.parse()
      |> Map.put(:meta, %{status: :ok})
    else
      err -> err
    end
  end

  # I cannot check so I consider everything is ok
  def check_unspent_utxo(%Tx{meta: %{status: :ok}} = tx), do: tx
  def check_unspent_utxo(err), do: err

  def expand_inputs(%Tx{meta: %{status: :ok}} = tx) do
    updated_inputs =
      tx
      |> Map.get(:inputs)
      |> Enum.map(fn txin ->
        case retrieve_out_online(txin.prev_tx, txin.prev_idx) do
          %TxOut{} = txout -> %{txin | meta: txout}
          _ -> %{txin | meta: :error}
        end
      end)

    tx
    |> Map.put(:inputs, updated_inputs)
    |> invalidate_if_errors()
  end

  def expand_inputs(err), do: err

  defp invalidate_if_errors(tx) do
    if Enum.any?(tx.inputs, fn i -> i.meta == :error end) do
      %{tx | meta: %{status: :error}}
    else
      tx
    end
  end

  def retrieve_out_online(hex, idx) do
    with hex <- Util.hex_lit_2_big(hex),
         %Tx{} = tx <- retrieve_tx_online(hex) do
      tx
      |> Map.get(:outputs)
      |> Enum.at(idx)
    else
      err -> err
    end
  end

  def check_fee(%Tx{meta: %{status: :ok}} = tx) do
    sat_in = tx.inputs |> Enum.map(fn i -> i.meta.amount end) |> Enum.sum()
    sat_ot = tx.outputs |> Enum.map(fn o -> o.amount end) |> Enum.sum()
    fee = sat_in - sat_ot

    case fee >= 0 do
      true -> %{tx | meta: %{fee: fee}}
      _ -> %{tx | meta: %{status: :error, fee: fee}}
    end
  end

  def check_fee(err), do: err

  def outside_query(tx) do
    case HTTPoison.get("https://mempool.space/api/tx/#{tx}/hex") do
      {:ok, %{body: raw}} -> {:ok, raw}
      err -> {:error, err}
    end
  end
end
