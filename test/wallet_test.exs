defmodule WalletTest do
  use ExUnit.Case
  alias Util
  alias Ec.Point256
  alias Wallet
  alias Ec.Signature

  test "verification of signed text" do
    hash = "BC62D4B80D9E36DA29C16C5D4D9F11731F36052C72401A76C23C0FB5A9B74423"
    key = "0204519FAC3D910CA7E7138F7013706F619FA8F033E6EC6E09370EA38CEE6A7574"

    signature =
      "3045022037206a0610995c58074999cb9767b87af4c4978db68c06e8e6e81d282047a7c6\
      0221008ca63759c1157ebeaec0d03cecca119fc9a75bf8e6d0fa65c841c8e2738cdaec"
      |> String.replace(~r/[\n|\s]+/, "")

    assert {:ok, "signature verified"} == Wallet.verify(hash, signature, key)
  end

  test "more verifications" do
    hash = "7c076ff316692a3d7eb3c3bb0f8b1488cf72e1afcd929e29307032997a838a3d"

    public_key =
      Point256.new(
        "887387e452b8eacc4acfde10d9aaf7f6d9a0f975aabb10d006e4da568744d06c",
        "61de6d95231cd89026e286df3b6ae4a894a3378e393e93a0f45b666329a0ae34"
      )
      |> Point256.serialize(true)

    sign =
      %Signature{
        r: Util.hex_2_int("eff69ef2b1bd93a66ed5219add4fb51e11a840f404876325a1e8ffe0529a2c"),
        s: Util.hex_2_int("c7207fee197d27c618aea621406f6bf5ef6fca38681d82b2f06fddbdce6feab6")
      }
      |> Signature.serialize()

    assert {:ok, "signature verified"} == Wallet.verify(hash, sign, public_key)
  end

  test "signing a text message" do
    with message <- "my message",
         cartera <- Wallet.new("my secret"),
         pub_k_h <- Wallet.pub_key_hex(cartera),
         %{hash: zh, signature: sh} <- Wallet.sign(message, cartera) do
      assert {:ok, "signature verified"} == Wallet.verify(zh, sh, pub_k_h)
    end
  end

  test "signing a number" do
    with message <- Enum.random(0..Integer.pow(2, 256)),
         cartera <- Wallet.new(Enum.random(0..Integer.pow(2, 256))),
         pub_k_h <- Wallet.pub_key_hex(cartera),
         %{hash: zh, signature: sh} <- Wallet.sign(message, cartera) do
      assert {:ok, "signature verified"} == Wallet.verify(zh, sh, pub_k_h)
    end
  end

  test "serialization of private key with WIF" do
    key = 5003 |> Wallet.new() |> Map.get(:private_key)

    assert Wallet.serial_private(key, :compr, :test) ==
             "cMahea7zqjxrtgAbB7LSGbcQUr1uX1ojuat9jZodMN8rFTv2sfUK"

    key = Integer.pow(2021, 5)

    assert Wallet.serial_private(key, false, :test) ==
             "91avARGdfge8E4tZfYLoxeJ5sGBdNJQH4kvjpWAxgzczjbCwxic"

    key = "54321deadbeef" |> Util.hex_2_int() |> Wallet.new() |> Map.get(:private_key)

    assert Wallet.serial_private(key, :compr, :main) ==
             "KwDiBf89QgGbjEhKnhXJuH7LrciVrZi3qYjgiuQJv1h8Ytr2S53a"

    key = (Integer.pow(2, 256) - Integer.pow(2, 199)) |> Wallet.new() |> Map.get(:private_key)

    assert Wallet.serial_private(key, :compr, :main) ==
             "L5oLkpV3aqBJ4BgssVAsax1iRa77G5CVYnv9adQ6Z87te7TyUdSC"

    key =
      "0dba685b4511dbd3d368e5c4358a1277de9486447af7b3604a69b8d9d8b7889d"
      |> Util.hex_2_int()
      |> Wallet.new()
      |> Map.get(:private_key)

    assert Wallet.serial_private(key, "something_dumb", :main) ==
             "5HvLFPDVgFZRK9cd4C5jcWki5Skz6fmKqi1GQJf5ZoMofid2Dty"
  end

  # test "verify transaction" do
  #   sig_hex =
  #     "3045022000eff69ef2b1bd93a66ed5219add4fb51e11a840f404876325a1e8ffe0529a2c022100c7207fee197d27c618aea621406f6bf5ef6fca38681d82b2f06fddbdce6feab601"
  #
  #   key_hex =
  #     "04887387e452b8eacc4acfde10d9aaf7f6d9a0f975aabb10d006e4da568744d06c61de6d95231cd89026e286df3b6ae4a894a3378e393e93a0f45b666329a0ae34"
  #
  #   Wallet.verify(
  #     sig_hex,
  #     key_hex,
  #     "7c076ff316692a3d7eb3c3bb0f8b1488cf72e1afcd929e29307032997a838a3d"
  #   )
  #   |> IO.inspect()
  # end
end
