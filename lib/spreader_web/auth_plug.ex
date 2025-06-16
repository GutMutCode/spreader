defmodule SpreaderWeb.AuthPlug do
  @moduledoc """
  Plug that assigns the current authenticated user to `conn.assigns.current_user`.

  • Checks session `:user_id` first.
  • Otherwise verifies `auth_token` cookie using `AuthToken`.
  • If valid user_id found, loads user from DB and assigns.
  """

  import Plug.Conn
  @behaviour Plug
  alias Spreader.Accounts.User
  alias Spreader.Repo
  alias SpreaderWeb.AuthToken

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    cond do
      current = conn.assigns[:current_user] -> assign(conn, :current_user, current)
      user_id = get_session(conn, :user_id) -> load_user(conn, user_id)
      token = fetch_auth_cookie(conn) -> verify_token(conn, token)
      true -> assign(conn, :current_user, nil)
    end
  end

  defp fetch_auth_cookie(conn) do
    conn.req_cookies["auth_token"]
  end

  defp verify_token(conn, token) do
    case AuthToken.verify(token) do
      {:ok, %{"user_id" => id}} -> load_user(conn, id)
      _ -> assign(conn, :current_user, nil)
    end
  end

  defp load_user(conn, user_id) do
    case Repo.get(User, user_id) do
      nil -> assign(conn, :current_user, nil)
      user -> assign(conn, :current_user, user)
    end
  end
end
