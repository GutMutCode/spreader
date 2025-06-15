defmodule Spreader.Accounts.User do
  @moduledoc """
  User schema for storing authentication information from Google OAuth.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "users" do
    field :email, :string
    field :name, :string
    field :avatar_url, :string
    field :provider, :string
    field :uid, :string
    field :tokens, :map

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :name, :avatar_url, :provider, :uid, :tokens])
    |> validate_required([:email])
    |> unique_constraint(:email)
  end
end
