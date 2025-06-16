defmodule SpreaderWeb.AuthTokenTest do
  use ExUnit.Case, async: true

  alias Spreader.Accounts.User
  alias SpreaderWeb.AuthToken

  describe "sign/1 & verify/1" do
    test "round-trip returns user_id" do
      token = AuthToken.sign(%User{id: 123})
      assert {:ok, %{user_id: 123}} = AuthToken.verify(token)
    end

    test "verify with wrong token returns error tuple" do
      assert {:error, _reason} = AuthToken.verify("invalid")
    end
  end
end
