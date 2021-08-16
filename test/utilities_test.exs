defmodule UtilitiesTest do
  use ExUnit.Case

  test "encode in base 58" do
    a =
      56_099_933_801_250_147_507_530_887_846_013_995_861_658_484_709_398_205_753_844_016_085_871_945_288_253

    b = "eff69ef2b1bd93a66ed5219add4fb51e11a840f404876325a1e8ffe0529a2c" |> :binary.decode_hex()

    c =
      90_067_678_915_080_561_991_476_742_139_334_357_116_447_229_582_337_733_602_832_701_972_810_841_451_190

    d = "000000997a838a3d" |> :binary.decode_hex()

    assert Utilities.encode_base58(<<a::big-size(256)>>) ==
             "9MA8fRQrT4u8Zj8ZRd6MAiiyaxb2Y1CMpvVkHQu5hVM6"

    assert Utilities.encode_base58(b) ==
             "4fE3H2E6XMp4SsxtwinF7w9a34ooUrwWe4WsW1458Pd"

    assert Utilities.encode_base58(<<c::big-size(256)>>) ==
             "EQJsjkd6JaGwxrjEhfeqPenqHwrBmPQZjJGNSCHBkcF7"

    assert Utilities.encode_base58(d) == "111JKJxfpQ"
  end
end
