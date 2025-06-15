defmodule SpreaderWeb.AuthFlowTest do
  @moduledoc """
  Integration tests that exercise the full browser pipeline for
  Google OAuth callback and logout. Ueberauth external calls are bypassed
  by injecting a fake %Ueberauth.Auth{} struct into conn.assigns before
  hitting the callback route.
  """

  use SpreaderWeb.ConnCase, async: true

  import Plug.Conn
  import Ecto.Query
  alias Spreader.Accounts.User
  alias Spreader.Repo

  setup %{conn: conn} do
    auth = %Ueberauth.Auth{
      provider: :google,
      uid: "test-uid",
      info: %Ueberauth.Auth.Info{
        email: "flow@example.com",
        name: "Flow Test",
        image: nil
      },
      credentials: %Ueberauth.Auth.Credentials{token: "xyz"}
    }

    {:ok, conn: assign(conn, :ueberauth_auth, auth)}
  end

  describe "login callback" do
    test "sets session and cookie and redirects", %{conn: conn} do
      conn = get(conn, ~p"/auth/google/callback")

      assert redirected_to(conn) == ~p"/"
      assert get_session(conn, :user_id)
      assert conn.resp_cookies["auth_token"].value

      # user persisted?
      assert Repo.one(from u in User, where: u.email == ^"flow@example.com")
    end
  end

  describe "logout" do
    test "clears session and cookie", %{conn: conn} do
      user = Repo.insert!(%User{email: "log@example.com"})
      conn = conn
             |> init_test_session(user_id: user.id)
             |> put_req_cookie("auth_token", "dummy")
             |> get(~p"/auth/logout")

      assert redirected_to(conn) == ~p"/"
      assert conn.private.plug_session_info == :drop
      assert conn.resp_cookies["auth_token"].max_age == 0
    end
  end
end
