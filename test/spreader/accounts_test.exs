defmodule Spreader.AccountsTest do
  use Spreader.DataCase, async: true

  alias Spreader.Accounts
  alias Ueberauth.{Auth, Auth.Credentials, Auth.Info}

  describe "get_or_create_user/1" do
    test "inserts a new user when email not found" do
      auth = %Auth{
        provider: :google,
        uid: "uid-123",
        info: %Info{email: "new@example.com", name: "New User", image: nil},
        credentials: %Credentials{token: "tok", expires_at: 1_900_000_000}
      }

      assert {:ok, user} = Accounts.get_or_create_user(auth)
      assert user.email == "new@example.com"
      assert [%{email: "new@example.com"}] = Spreader.Repo.all(Spreader.Accounts.User)
    end

    test "returns existing user when email matches" do
      existing = %Spreader.Accounts.User{email: "dup@example.com"} |> Spreader.Repo.insert!()

      auth = %Auth{
        provider: :google,
        uid: "uid-999",
        info: %Info{email: existing.email, name: "Dup", image: nil},
        credentials: %Credentials{token: "tok", expires_at: 1_900_000_000}
      }

      assert {:ok, user} = Accounts.get_or_create_user(auth)
      assert user.id == existing.id
      assert Spreader.Repo.aggregate(Spreader.Accounts.User, :count, :id) == 1
    end
  end
end
