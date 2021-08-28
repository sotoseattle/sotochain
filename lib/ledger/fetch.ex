defmodule Ledger.Fetch do
  alias Ledger.Tx
  alias Ledger.TxOut
  alias Ledger.Fetch

  defstruct valid: nil, tx: nil, error: nil, raw: nil

  def fetch(tx_id) do
    tx_id
    |> retrieve_tx_online()
    |> parse_tx_blurb()
    |> check_unspent_utxo()
    |> retrieve_prev_outputs()
    |> check_fee()
    |> verify_inputs()
  end

  @doc "get the hex blur of a transaction from an online source"
  def retrieve_tx_online(tx_hex) do
    case HTTPoison.get("https://mempool.space/api/tx/#{tx_hex}/hex") do
      {:ok, %{body: raw}} ->
        %Fetch{valid: true, raw: raw}

      err ->
        %Fetch{valid: false, error: err}
    end
  end

  @doc "parse the transaction into its struct"
  def parse_tx_blurb(%{valid: false} = fo), do: fo

  def parse_tx_blurb(fo) do
    with %Tx{} = tx <- Tx.parse(fo.raw) do
      %{fo | tx: tx, raw: nil}
    else
      err -> %{fo | valid: false, error: err}
    end
  end

  # I cannot check so I consider everything is ok
  def check_unspent_utxo(fo), do: fo

  def retrieve_prev_outputs(%{valid: false} = fo), do: fo

  def retrieve_prev_outputs(fo) do
    updated_inputs =
      fo
      |> Map.get(:tx)
      |> Map.get(:inputs)
      |> Enum.map(fn txin ->
        %{txin | meta: extract_output(txin.prev_tx, txin.prev_idx)}
      end)

    %{fo | tx: %{fo.tx | inputs: updated_inputs}}
    |> invalidate_if_errors()
  end

  def extract_output(hex, idx) do
    with hex <- Util.hex_lit_2_big(hex),
         %{valid: true} = fo <- retrieve_tx_online(hex),
         %{valid: true} = fo <- parse_tx_blurb(fo) do
      fo
      |> Map.get(:tx)
      |> Map.get(:outputs)
      |> Enum.at(idx)
    else
      bad_fo -> bad_fo.error
    end
  end

  defp invalidate_if_errors(fo) do
    if Enum.all?(fo.tx.inputs, fn i -> is_struct(i.meta, TxOut) end) do
      fo
    else
      %{fo | valid: false, error: "previous tx outputs unavailable"}
    end
  end

  def check_fee(%{valid: false} = fo), do: fo

  def check_fee(fo) do
    fee = Tx.fee(fo.tx)

    case fee >= 0 do
      true -> %{fo | tx: %{fo.tx | meta: %{fee: fee}}}
      _ -> %{fo | valid: false, error: "insuficient fee: #{fee} sat"}
    end
  end

  def verify_inputs(%{valid: false} = fo), do: fo

  def verify_inputs(fo) do
    case Tx.verify_inputs(fo.tx) do
      {:ok, tx} -> %{fo | tx: tx}
      {:error, err} -> %{fo | valid: false, error: err}
    end
  end

  def outside_query(tx) do
    case HTTPoison.get("https://mempool.space/api/tx/#{tx}/hex") do
      {:ok, %{body: raw}} -> {:ok, raw}
      err -> {:error, err}
    end
  end
end
