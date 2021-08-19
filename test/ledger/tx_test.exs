defmodule TxTest do
  use ExUnit.Case

  test "parse transaction" do
    tx1 =
      """
      010000000456919960ac691763688d3d3bcea9ad6ecaf875df5339e148a1fc61c6ed7a069
      e010000006a47304402204585bcdef85e6b1c6af5c2669d4830ff86e42dd205c0e089bc2a
      821657e951c002201024a10366077f87d6bce1f7100ad8cfa8a064b39d4e8fe4ea13a7b71
      aa8180f012102f0da57e85eec2934a82a585ea337ce2f4998b50ae699dd79f5880e253daf
      afb7feffffffeb8f51f4038dc17e6313cf831d4f02281c2a468bde0fafd37f1bf882729e7
      fd3000000006a47304402207899531a52d59a6de200179928ca900254a36b8dff8bb75f5f
      5d71b1cdc26125022008b422690b8461cb52c3cc30330b23d574351872b7c361e9aae3649
      071c1a7160121035d5c93d9ac96881f19ba1f686f15f009ded7c62efe85a872e6a19b43c1
      5a2937feffffff567bf40595119d1bb8a3037c356efd56170b64cbcc160fb028fa10704b4
      5d775000000006a47304402204c7c7818424c7f7911da6cddc59655a70af1cb5eaf17c69d
      adbfc74ffa0b662f02207599e08bc8023693ad4e9527dc42c34210f7a7d1d1ddfc8492b65
      4a11e7620a0012102158b46fbdff65d0172b7989aec8850aa0dae49abfb84c81ae6e5b251
      a58ace5cfeffffffd63a5e6c16e620f86f375925b21cabaf736c779f88fd04dcad51d2669
      0f7f345010000006a47304402200633ea0d3314bea0d95b3cd8dadb2ef79ea8331ffe1e61
      f762c0f6daea0fabde022029f23b3e9c30f080446150b23852028751635dcee2be669c2a1
      686a4b5edf304012103ffd6f4a67e94aba353a00882e563ff2722eb4cff0ad6006e86ee20
      dfe7520d55feffffff0251430f00000000001976a914ab0c0b2e98b1ab6dbf67d4750b0a5
      6244948a87988ac005a6202000000001976a9143c82d7df364eb6c75be8c80df2b3eda8db
      57397088ac46430600
      """
      |> String.upcase()
      |> String.replace(~r/[\n|\s]+/, "")

    t = Transaction.new(tx1)
    assert t.version == 1
    assert t.locktime == 410_438
    assert length(t.inputs) == 4
    assert length(t.outputs) == 2

    indexes = t.inputs |> Enum.map(fn x -> x.prev_idx end) |> Enum.uniq() |> Enum.sort()
    assert indexes == [0, 1]

    addresses = t.inputs |> Enum.map(fn x -> x.prev_tx end)
    assert "56919960AC691763688D3D3BCEA9AD6ECAF875DF5339E148A1FC61C6ED7A069E" in addresses

    amounts = t.outputs |> Enum.map(fn x -> x.amount end)
    assert 1_000_273 in amounts
    assert 40_000_000 in amounts

    assert Ledger.Tx.serialize(t) == tx1
  end
end
