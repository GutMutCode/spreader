defmodule Spreader.Repo do
  use Ecto.Repo,
    otp_app: :spreader,
    adapter: Ecto.Adapters.Postgres
end
