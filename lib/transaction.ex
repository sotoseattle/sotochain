defmodule Transaction do
  alias Ledger.Tx

  def new(), do: %Tx{}
  def new(hex_string) when is_binary(hex_string), do: Tx.parse(hex_string)

  def id(%Tx{} = tx), do: Tx.id(tx)

  def serialize(%Tx{} = tx), do: Tx.serialize(tx)
end
