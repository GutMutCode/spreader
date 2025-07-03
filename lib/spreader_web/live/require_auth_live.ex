defmodule SpreaderWeb.RequireAuthLive do
  @moduledoc """
  on_mount callback used by LiveViews that require an authenticated user.

  If `:current_user` is present in the socket assigns (set by `SpreaderWeb.AuthPlug`),
  the LiveView continues as normal. Otherwise the user is redirected to the Google
  OAuth request path and the LiveView mounting process halts.
  """

  import Phoenix.LiveView
alias Spreader.Accounts.User
alias Spreader.Repo

  def on_mount(_name, _params, %{"user_id" => user_id} = _session, socket) do
    cond do
      socket.assigns[:current_user] ->
        {:cont, socket}

      user = user_id && Repo.get(User, user_id) ->
        {:cont, Phoenix.Component.assign(socket, :current_user, user)}

      true ->
        socket
        |> put_flash(:error, "Please sign in to continue.")
        |> redirect(to: "/auth/google")
        |> halt()
    end
  end

  defp halt(socket), do: {:halt, socket}
end
