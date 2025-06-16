defmodule SpreaderWeb.TermsHTML do
  @moduledoc "HTML templates for Terms of Service pages"

  use SpreaderWeb, :html
  import SpreaderWeb.Gettext

  # Looks for templates in lib/spreader_web/templates/terms_html/
  embed_templates "terms_html/*"
end
