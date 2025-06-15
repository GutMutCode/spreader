defmodule SpreaderWeb.AuthToken do
  @moduledoc """
  Simple helper for signing and verifying JWT-like tokens using `Phoenix.Token`.

  • sign/1   – produce token containing user_id
  • verify/1 – verify token, default max_age 30 days
  """

  alias SpreaderWeb.Endpoint

  @salt "user auth"

  @doc "Generate a signed token for given %User{} struct."
  @spec sign(Spreader.Accounts.User.t()) :: String.t()
  def sign(%Spreader.Accounts.User{id: user_id}) when is_integer(user_id) do
    Phoenix.Token.sign(Endpoint, @salt, %{user_id: user_id})
  end

  @doc "Verify a token and return {:ok, payload} | :error"
  @spec verify(String.t(), non_neg_integer()) :: {:ok, map()} | :error
  def verify(token, max_age \\ 2_592_000) do  # 30 days
    Phoenix.Token.verify(Endpoint, @salt, token, max_age: max_age)
  end
end
