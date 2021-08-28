defmodule Ledger.Fetch do
  alias Ledger.Tx
  alias Ledger.TxOut
  alias Ledger.Fetch

  defstruct valid: nil, tx: nil, error: nil, raw: nil, net: nil

  def new(params, fo \\ %Fetch{})
  def new([], fo), do: fo
  def new([{k, v} | t], %Fetch{} = fo), do: new(t, Map.put(fo, k, v))

  def fetch(tx_id, net \\ :test) do
    new(valid: true)
    |> set_network(net)
    |> retrieve_tx_online(tx_id)
    |> parse_tx_blurb()
    |> check_unspent_utxo()
    |> retrieve_prev_outputs()
    |> check_fee()
    |> verify_inputs()
  end

  def set_network(fo, :test), do: %{fo | net: :test}
  def set_network(fo, :main), do: %{fo | net: :main}
  def set_network(fo, _), do: %{fo | valid: false, error: "unrecognized network"}

  @doc "get the hex blur of a transaction from an online source"
  def retrieve_tx_online(fo, tx_hex) do
    case HTTPoison.get(btcurl(fo.net) <> "#{tx_hex}/hex") do
      {:ok, %{status_code: 200, body: raw}} ->
        %{fo | raw: raw}

      err ->
        %{fo | valid: false, error: err}
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
        %{txin | meta: extract_output(fo.net, txin.prev_tx, txin.prev_idx)}
      end)

    %{fo | tx: %{fo.tx | inputs: updated_inputs}}
    |> invalidate_if_errors()
  end

  def extract_output(net, hex, idx) do
    with hex <- Util.hex_lit_2_big(hex),
         temp_fo <- new(valid: true, net: net),
         %{valid: true} = fo <- retrieve_tx_online(temp_fo, hex),
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

  defp btcurl(:test), do: "https://mempool.space/testnet/api/tx/"
  defp btcurl(:main), do: "https://mempool.space/api/tx/"
end
