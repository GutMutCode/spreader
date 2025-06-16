defmodule SpreaderWeb.TermsController do
  @moduledoc """
  Renders the Terms of Service page for the requested locale.
  """

  use SpreaderWeb, :controller

  # GET /terms-of-service/:locale
  def show(conn, %{"locale" => locale}) do
    render(conn, "#{locale}.html", layout: {SpreaderWeb.Layouts, :root})
  end
end
