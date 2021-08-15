defmodule SignatureTest do
  use ExUnit.Case

  test "serialization of signature according to DER" do
    sign = %Ec.Signature{
      r:
        24_934_477_526_773_085_068_622_965_895_147_445_253_088_155_263_472_363_298_185_420_205_900_230_535_110,
      s:
        63_617_477_430_228_947_890_476_775_612_691_984_600_680_877_069_283_092_420_476_557_621_266_469_411_564
    }

    assert Ec.Signature.serialize(sign) ==
             "3045022037206a0610995c58074999cb9767b87af4c4978db68c06e8e6e81d282047a7c60221008ca63759c1157ebeaec0d03cecca119fc9a75bf8e6d0fa65c841c8e2738cdaec"
             |> String.upcase()
  end
end
