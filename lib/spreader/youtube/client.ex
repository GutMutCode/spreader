defmodule Spreader.YouTube.Client do
  @moduledoc """
  Thin wrapper around `GoogleApi.YouTube.V3` that builds an authenticated
  connection for the given user. Tokens are stored in the `tokens` map of the
  `Spreader.Accounts.User` schema under the keys:

      "youtube_access_token"
      "youtube_refresh_token"
      "youtube_token_expires_at" (unix seconds)

  If the access token is near expiry (or already expired) we transparently
  refresh it using Google's OAuth 2 token endpoint and persist the new tokens
  back to the DB.
  """
  alias GoogleApi.YouTube.V3.Connection
  require Logger
  alias Spreader.{Repo, Accounts.User}

  @token_url "https://oauth2.googleapis.com/token"

  @doc """
  Returns `{:ok, conn}` or `{:error, reason}`.
  """
  @spec connection(User.t()) :: {:ok, Connection.t()} | {:error, term()}
  def connection(%User{} = user) do
    with {:ok, token} <- get_or_refresh_token(user) do
      {:ok, Connection.new(token)}
    end
  end

  # --------------------------------------------------------------------------
  # Helpers
  # --------------------------------------------------------------------------

  defp get_or_refresh_token(%User{} = user) do
    tokens = user.tokens || %{}

    # Prefer namespaced keys; fall back to generic OAuth keys saved by AuthController
    access  = Map.get(tokens, "youtube_access_token", Map.get(tokens, "access_token"))
    refresh = Map.get(tokens, "youtube_refresh_token", Map.get(tokens, "refresh_token"))
    exp     = Map.get(tokens, "youtube_token_expires_at", Map.get(tokens, "expires_at", 0))

    cond do
      is_nil(access) or is_nil(refresh) ->
        {:error, :missing_tokens}

      exp <= now() + 60 ->
        refresh_token(user, refresh)

      true ->
        {:ok, access}
    end
  end

  defp refresh_token(%User{} = user, refresh_token) do
    client_id     = System.fetch_env!("YT_CLIENT_ID")
    client_secret = System.fetch_env!("YT_CLIENT_SECRET")

    body = URI.encode_query(%{
      client_id: client_id,
      client_secret: client_secret,
      refresh_token: refresh_token,
      grant_type: "refresh_token"
    })

    headers = [{"content-type", "application/x-www-form-urlencoded"}]

    case :hackney.request(:post, @token_url, headers, body, []) do
      {:ok, 200, _hdrs, client_ref} ->
        {:ok, resp_body} = :hackney.body(client_ref)
        case Jason.decode(resp_body) do
          {:ok, %{"access_token" => new_access, "expires_in" => expires}} ->
            tokens = user.tokens |> Map.put("youtube_access_token", new_access)
                                   |> Map.put("youtube_token_expires_at", now() + expires)
            # Persist silently; ignore result – token can still be used even if DB fails
            _ = user |> Ecto.Changeset.change(tokens: tokens) |> Repo.update()
            {:ok, new_access}

          err ->
            Logger.error("[YouTube] failed to decode refresh response: #{inspect(err)}")
            {:error, :invalid_refresh_response}
        end

      {:ok, status, _hdrs, client_ref} ->
        {:ok, body} = :hackney.body(client_ref)
        Logger.error("[YouTube] refresh token failed #{status}: #{body}")
        {:error, {:http_error, status}}

      err ->
        Logger.error("[YouTube] refresh token request error: #{inspect(err)}")
        {:error, err}
    end
  end

  defp now, do: DateTime.utc_now() |> DateTime.to_unix()
end
