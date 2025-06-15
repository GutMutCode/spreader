defmodule Spreader.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, null: false
      add :name, :string
      add :avatar_url, :string
      add :provider, :string
      add :uid, :string
      add :tokens, :map

      timestamps()
    end

    create unique_index(:users, [:email])
  end
end
