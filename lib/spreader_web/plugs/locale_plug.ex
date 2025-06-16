defmodule SpreaderWeb.LocalePlug do
  @moduledoc """
  A plug that sets the locale for the request based on the `:locale` path
  parameter (e.g. `/terms-of-service/en`).  If the requested locale is not
  supported, the plug redirects to the default locale.
  """

  import Plug.Conn
  import Phoenix.Controller

  @behaviour Plug

  # Supported locales. Update the list when you add more translations.
  @locales ~w(en ko)
  @default_locale hd(@locales)

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(%Plug.Conn{params: %{"locale" => locale}} = conn, _opts) do
    if locale in @locales do
      Gettext.put_locale(locale)
      assign(conn, :locale, locale)
    else
      conn
      |> redirect(to: "/terms-of-service/#{@default_locale}")
      |> halt()
    end
  end

  def call(conn, _opts) do
    # No locale in params: default & continue (useful for non-localized routes)
    Gettext.put_locale(@default_locale)
    assign(conn, :locale, @default_locale)
  end
end
