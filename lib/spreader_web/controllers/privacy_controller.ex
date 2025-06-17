defmodule SpreaderWeb.PrivacyController do
  @moduledoc """
  Renders the Privacy Policy page for the requested locale.
  """

  use SpreaderWeb, :controller

  # GET /privacy/:locale  (dev-only: /gmc/privacy/:locale)
  def show(conn, %{"locale" => locale}) do
    render(conn, "#{locale}.html", layout: {SpreaderWeb.Layouts, :root})
  end
end
