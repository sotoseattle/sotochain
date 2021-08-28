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

  test "compute the signature hash of a transaction" do
    tx =
      "0100000001813f79011acb80925dfe69b3def355fe914bd1d96a3f5f71bf830\
      3c6a989c7d1000000006b483045022100ed81ff192e75a3fd2304004dcadb746fa5e24c5031ccf\
      cf21320b0277457c98f02207a986d955c6e0cb35d446a89d3f56100f4d7f67801c31967743a9c8\
      e10615bed01210349fc4e631e3624a545de3f89f5d8684c7b8138bd94bdd531d2e213bf016b278\
      afeffffff02a135ef01000000001976a914bc3b654dca7e56b04dca18f2566cdaf02e8d9ada88a\
      c99c39800000000001976a9141c4bc762dd5423e332166702cb75f40df79fea1288ac19430600"
      |> String.replace(~r/[\n|\s]+/, "")
      |> Ledger.Tx.parse()

    i =
      tx.inputs
      |> List.first()
      |> Map.put(:meta, %Ledger.TxOut{
        amount: 229_566_594,
        script_key: "76a914a802fc56c704ce87c42d7c92eb75e7896bdc41ae88ac"
      })

    tx = %{tx | inputs: [i]}

    tx = Ledger.Tx.compute_sig_hashes(tx)
    zoo = tx.inputs |> List.first() |> Map.get(:sig_hash)

    assert zoo ==
             "27e0c5994dec7824e56dec6b2fcb342eb7cdb0d0957c2fce9882f715e85d81a6"
             |> Util.hex_2_int()

    assert Ledger.Tx.verify_inputs(tx)
  end

  test "verify real transaction from internet" do
    tx =
      "0100000001032e38e9c0a84c6046d687d10556dcacc41d275ec55fc00779ac88fdf357a187000000008c493046022100c352d3dd993a981beba4a63ad15c209275ca9470abfcd57da93b58e4eb5dce82022100840792bc1f456062819f15d33ee7055cf7b5ee1af1ebcc6028d9cdb1c3af7748014104f46db5e9d61a9dc27b8d64ad23e7383a4e6ca164593c2527c038c0857eb67ee8e825dca65046b82c9331586c82e0fd1f633f25f87c161bc6f8a630121df2b3d3ffffffff0200e32321000000001976a914c398efa9c392ba6013c5e04ee729755ef7f58b3288ac000fe208010000001976a914948c765a6914d43f2a7ac177da2c2f6b52de3d7c88ac00000000"
      |> String.replace(~r/[\n|\s]+/, "")
      |> Ledger.Tx.parse()

    i =
      tx.inputs
      |> List.first()
      |> Map.put(:meta, %Ledger.TxOut{
        amount: 229_566_594,
        script_key: "76a91471d7dd96d9edda09180fe9d57a477b5acc9cad1188ac"
      })

    tx = %{tx | inputs: [i]}

    assert Ledger.Tx.verify_inputs(tx) |> elem(0) == :ok
  end

  test "verify real transaction from internet 2" do
    tx = %Ledger.Tx{
      inputs: [
        %Ledger.TxIn{
          meta: %Ledger.TxOut{
            amount: 229_566_594,
            script_key: "76A914FF6208DD9E764CB27E3F10C89DB0B1F7FB589CEB88AC"
          },
          prev_idx: 1,
          prev_tx: "7FD64DF94CCEDD9E7F3B3A9EF072FD184F9E89DC5CF3E233D0029AC03DC6B7BC",
          script_sig:
            "473044022056C003F79D7C2192138D70B6627521299CEBBEC6C4BAE670DB2E41A30575EA54022042EA592881DD88311EA3855E8A7B4F7BA4443C779E5E9CA2820B702AE318C892012103E6CBFD24EC873BC7243053B40A2C1ED80D7C21C03022F235A7E21B1F6FF7DAF4",
          seq: "FFFFFFFF"
        }
      ],
      locktime: 0,
      meta: %{fee: 10000},
      net: :main,
      outputs: [
        %Ledger.TxOut{
          amount: 42_057_450,
          script_key: "76A9147A18ECFE673427C2A6E5A34E06F3AD7ED73C7C2C88AC"
        },
        %Ledger.TxOut{
          amount: 187_499_144,
          script_key: "76A914FF6208DD9E764CB27E3F10C89DB0B1F7FB589CEB88AC"
        }
      ],
      version: 1
    }

    assert Ledger.Tx.verify_inputs(tx) |> elem(0) == :ok
  end

  test "refute a wrong transaction whose input points to a wrong prev output" do
    tx = %Ledger.Tx{
      inputs: [
        %Ledger.TxIn{
          meta: %Ledger.TxOut{
            amount: 229_566_594,
            script_key: "76a91471d7dd96d9edda09180fe9d57a477b5acc9cad1188ac"
          },
          prev_idx: 1,
          prev_tx: "7FD64DF94CCEDD9E7F3B3A9EF072FD184F9E89DC5CF3E233D0029AC03DC6B7BC",
          script_sig:
            "473044022056C003F79D7C2192138D70B6627521299CEBBEC6C4BAE670DB2E41A30575EA54022042EA592881DD88311EA3855E8A7B4F7BA4443C779E5E9CA2820B702AE318C892012103E6CBFD24EC873BC7243053B40A2C1ED80D7C21C03022F235A7E21B1F6FF7DAF4",
          seq: "FFFFFFFF"
        }
      ],
      locktime: 0,
      meta: %{fee: 10000},
      net: :main,
      outputs: [
        %Ledger.TxOut{
          amount: 42_057_450,
          script_key: "76A9147A18ECFE673427C2A6E5A34E06F3AD7ED73C7C2C88AC"
        },
        %Ledger.TxOut{
          amount: 187_499_144,
          script_key: "76A914FF6208DD9E764CB27E3F10C89DB0B1F7FB589CEB88AC"
        }
      ],
      version: 1
    }

    assert Ledger.Tx.verify_inputs(tx) |> elem(0) == :error
  end
end
