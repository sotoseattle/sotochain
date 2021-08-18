defmodule UtilTest do
  use ExUnit.Case

  test "encode in base 58" do
    a =
      56_099_933_801_250_147_507_530_887_846_013_995_861_658_484_709_398_205_753_844_016_085_871_945_288_253

    b = "eff69ef2b1bd93a66ed5219add4fb51e11a840f404876325a1e8ffe0529a2c" |> :binary.decode_hex()

    c =
      90_067_678_915_080_561_991_476_742_139_334_357_116_447_229_582_337_733_602_832_701_972_810_841_451_190

    d = "000000997a838a3d" |> :binary.decode_hex()

    assert Util.encode_base58(<<a::big-size(256)>>) ==
             "9MA8fRQrT4u8Zj8ZRd6MAiiyaxb2Y1CMpvVkHQu5hVM6"

    assert Util.encode_base58(b) ==
             "4fE3H2E6XMp4SsxtwinF7w9a34ooUrwWe4WsW1458Pd"

    assert Util.encode_base58(<<c::big-size(256)>>) ==
             "EQJsjkd6JaGwxrjEhfeqPenqHwrBmPQZjJGNSCHBkcF7"

    assert Util.encode_base58(d) == "111JKJxfpQ"
  end

  test "little endian" do
    assert Util.hex_2_litt("01000000") == 1
  end

  test "varint" do
    assert Util.int_2_varint(100) == "64"
    assert Util.int_2_varint(255) == "FDFF00"
    assert Util.int_2_varint(555) == "FD2B02"
    assert Util.int_2_varint(70015) == "FE7F110100"
    assert Util.int_2_varint(18_005_558_675_309) == "FF6DC7ED3E60100000"

    assert Util.parse_varint(:binary.decode_hex("64")) == {100, ""}
    assert Util.parse_varint(:binary.decode_hex("FDFF00")) == {255, ""}
    assert Util.parse_varint(:binary.decode_hex("FD2B02")) == {555, ""}
    assert Util.parse_varint(:binary.decode_hex("FE7F110100")) == {70015, ""}
    assert Util.parse_varint(:binary.decode_hex("FF6DC7ED3E60100000")) == {18_005_558_675_309, ""}
  end
end
