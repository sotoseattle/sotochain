defmodule SignatureTest do
  use ExUnit.Case
  alias Ec.Point256
  alias Ec.Signature

  test "serialization of signature according to DER" do
    sig_hex =
      "3045022037206a0610995c58074999cb9767b87af4c4978db68c06e8e6e81d282047a7c60221008ca63759c1157ebeaec0d03cecca119fc9a75bf8e6d0fa65c841c8e2738cdaec"
      |> String.upcase()

    sign = %Ec.Signature{
      r:
        24_934_477_526_773_085_068_622_965_895_147_445_253_088_155_263_472_363_298_185_420_205_900_230_535_110,
      s:
        63_617_477_430_228_947_890_476_775_612_691_984_600_680_877_069_283_092_420_476_557_621_266_469_411_564
    }

    assert Signature.serialize(sign) == sig_hex

    # THIS 01 addition is so WRONG
    assert Signature.parse(sig_hex <> "01") == sign
  end

  test "verification of signed text" do
    z =
      85_209_434_678_292_214_399_516_606_369_540_687_209_995_712_346_561_802_549_023_407_573_798_789_530_659

    r =
      24_934_477_526_773_085_068_622_965_895_147_445_253_088_155_263_472_363_298_185_420_205_900_230_535_110

    s =
      63_617_477_430_228_947_890_476_775_612_691_984_600_680_877_069_283_092_420_476_557_621_266_469_411_564

    public_key =
      Point256.new(
        1_953_468_027_843_800_802_925_170_596_235_937_825_164_475_810_165_197_027_149_199_811_512_646_661_492,
        59_120_681_311_850_885_220_056_534_314_674_652_481_360_305_757_776_226_951_480_641_546_728_038_708_932
      )

    signature = %Signature{r: r, s: s}

    assert {:ok, "signature verified"} == Signature.verify(z, signature, public_key)
  end

  defp rando(), do: Enum.random(0..Integer.pow(2, 256))

  test "brute force cycles of serialization and parsing" do
    testcases = [[1, 2], [rando(), rando()], [rando(), rando()]]

    for [r, s] <- testcases do
      sig = %Signature{r: r, s: s}
      der = Signature.serialize(sig)
      sig2 = Signature.parse(der)
      assert sig2.r == r
      assert sig2.s == s
    end
  end
end
