defmodule SpreaderWeb.TermsHTML do
  @moduledoc "HTML templates for Terms of Service pages"

  use SpreaderWeb, :html

  # Looks for templates in lib/spreader_web/templates/terms_html/
  embed_templates "../templates/terms_html/*"
end
