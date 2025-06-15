defmodule Spreader.Accounts do
  @moduledoc """
  Accounts context responsible for managing user records.
  """

  alias Spreader.Repo
  alias Spreader.Accounts.User

  @spec get_or_create_user(Ueberauth.Auth.t()) :: {:ok, User.t()} | {:error, term()}
  def get_or_create_user(%Ueberauth.Auth{} = auth) do
    email = auth.info.email

    params = %{
      email: email,
      name: auth.info.name,
      avatar_url: auth.info.image,
      provider: to_string(auth.provider),
      uid: auth.uid,
      tokens: %{
        "access_token" => auth.credentials.token,
        "refresh_token" => auth.credentials.refresh_token,
        "expires_at" => auth.credentials.expires_at
      }
    }

    case Repo.get_by(User, email: email) do
      nil ->
        %User{}
        |> User.changeset(params)
        |> Repo.insert()

      user ->
        {:ok, user}
    end
  end
end
