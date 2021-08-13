defmodule Point256Test do
  use ExUnit.Case
  alias Ec.Fifi
  alias Ec.Point256
  alias Ec.Point
  alias Ec.Fasto

  doctest Ec.Point

  test "in the real deal" do
    x =
      55_066_263_022_277_343_669_578_718_895_168_534_326_250_603_453_777_594_175_500_187_360_389_116_729_240

    y =
      32_670_510_020_758_816_978_083_085_130_507_043_184_471_273_380_659_243_275_938_904_335_757_337_482_424

    n =
      115_792_089_237_316_195_423_570_985_008_687_907_852_837_564_279_074_904_382_605_163_141_518_161_494_337

    assert g = Point256.new(x, y)
    assert Point256.dot(g, n) == Point256.infinite_point()
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

    assert Point256.is_verified(p_key: public_key, hash: z, r: r, s: s)
  end

  test "more verifications" do
    public_key =
      Point256.new(
        "887387e452b8eacc4acfde10d9aaf7f6d9a0f975aabb10d006e4da568744d06c",
        "61de6d95231cd89026e286df3b6ae4a894a3378e393e93a0f45b666329a0ae34"
      )

    z = Point256.hex_int("ec208baa0fc1c19f708a9ca96fdeff3ac3f230bb4a7ba4aede4942ad003c0f60")
    r = Point256.hex_int("ac8d1c87e51d0d441be8b3dd5b05c8795b48875dffe00b7ffcfac23010d3a395")
    s = Point256.hex_int("68342ceff8935ededd102dd876ffd6ba72d6a427a3edb13d26eb0781cb423c4")

    assert Point256.is_verified(p_key: public_key, hash: z, r: r, s: s)

    z = Point256.hex_int("7c076ff316692a3d7eb3c3bb0f8b1488cf72e1afcd929e29307032997a838a3d")
    r = Point256.hex_int("eff69ef2b1bd93a66ed5219add4fb51e11a840f404876325a1e8ffe0529a2c")
    s = Point256.hex_int("c7207fee197d27c618aea621406f6bf5ef6fca38681d82b2f06fddbdce6feab6")

    assert Point256.is_verified(p_key: public_key, hash: z, r: r, s: s)
  end
end
