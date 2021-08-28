defmodule ScriptTest do
  use ExUnit.Case

  alias Ledger.Script

  test "operations" do
    # assert Script.op_2dup([1, 2, 3]) == [1, 2, 1, 2, 3]
    # assert Script.op_2dup([1, 2]) == [1, 2, 1, 2]
    # assert Script.op_2dup([1]) == [false]
    # assert Script.op_2dup([]) == [false]
    #
    # assert Script.op_dup([1, 2, 3]) == [1, 1, 2, 3]
    # assert Script.op_dup([1]) == [1, 1]
    # assert Script.op_dup([]) == [false]
    #
    # assert Script.op_equal([1, 1, 2, 3]) == [1, 2, 3]
    # assert Script.op_equal([1, 1]) == [1]
    # assert Script.op_equal([1, 2, 2, 3]) == [0, 2, 3]
    # assert Script.op_equal([1, 2]) == [0]
    # assert Script.op_equal([1]) == [false]
    # assert Script.op_equal([]) == [false]
  end

  test "evaluate script with collision example" do
    c1 =
      "255044462d312e330a25e2e3cfd30a0a0a312030206f626a0a3c3c2f5769647468203220\
    3020522f4865696768742033203020522f547970652034203020522f5375627479706520352\
    03020522f46696c7465722036203020522f436f6c6f7253706163652037203020522f4c656e\
    6774682038203020522f42697473506572436f6d706f6e656e7420383e3e0a73747265616d0\
    affd8fffe00245348412d3120697320646561642121212121852fec092339759c39b1a1c63c\
    4c97e1fffe017f46dc93a6b67e013b029aaa1db2560b45ca67d688c7f84b8c4c791fe02b3df\
    614f86db1690901c56b45c1530afedfb76038e972722fe7ad728f0e4904e046c230570fe9d4\
    1398abe12ef5bc942be33542a4802d98b5d70f2a332ec37fac3514e74ddc0f2cc1a874cd0c7\
    8305a21566461309789606bd0bf3f98cda8044629a1"
      |> String.replace(~r/[\n|\s]+/, "")
      |> :binary.decode_hex()

    c2 =
      "255044462d312e330a25e2e3cfd30a0a0a312030206f626a0a3c3c2f5769647468203220
    3020522f4865696768742033203020522f547970652034203020522f5375627479706520352\
    03020522f46696c7465722036203020522f436f6c6f7253706163652037203020522f4c656e\
    6774682038203020522f42697473506572436f6d706f6e656e7420383e3e0a73747265616d0\
    affd8fffe00245348412d3120697320646561642121212121852fec092339759c39b1a1c63c\
    4c97e1fffe017346dc9166b67e118f029ab621b2560ff9ca67cca8c7f85ba84c79030c2b3de\
    218f86db3a90901d5df45c14f26fedfb3dc38e96ac22fe7bd728f0e45bce046d23c570feb14\
    1398bb552ef5a0a82be331fea48037b8b5d71f0e332edf93ac3500eb4ddc0decc1a864790c7\
    82c76215660dd309791d06bd0af3f98cda4bc4629b1"
      |> String.replace(~r/[\n|\s]+/, "")
      |> :binary.decode_hex()

    s = Ledger.Script.parse("6e879169a77ca787")

    assert Ledger.Script.evaluate(s, [c1, c2])
  end

  test "mini verification with simple math" do
    script_pubkey = "767695935687" |> Script.parse()

    script_sig = "52" |> Script.parse()

    assert Script.combine(script_sig, script_pubkey) |> Script.evaluate()
  end
end
