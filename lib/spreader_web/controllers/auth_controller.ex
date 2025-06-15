defmodule SpreaderWeb.AuthController do
  @moduledoc """
  Handles Google OAuth flow using Ueberauth.
  """

  use SpreaderWeb, :controller

  plug Ueberauth

  alias Spreader.Accounts

  # Initiates OAuth request (handled by Ueberauth strategy)
  def request(conn, _params), do: conn

  # Successful callback
  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    case Accounts.get_or_create_user(auth) do
      {:ok, user} ->
        token = SpreaderWeb.AuthToken.sign(user)

        conn
        |> put_session(:user_id, user.id)
        |> put_session(:auth_token, token)
        |> put_resp_cookie("auth_token", token, http_only: true, same_site: "Lax")
        |> configure_session(renew: true)
        |> put_flash(:info, "Signed in successfully")
        |> redirect(to: ~p"/")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Authentication failed: #{inspect(reason)}")
        |> redirect(to: ~p"/")
    end
  end

  # Failure callback
  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    conn
    |> put_flash(:error, "Authentication failed")
    |> redirect(to: ~p"/")
  end

  # Logout
  def logout(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> delete_resp_cookie("auth_token")
    |> put_flash(:info, "Logged out")
    |> redirect(to: ~p"/")
  end
end
