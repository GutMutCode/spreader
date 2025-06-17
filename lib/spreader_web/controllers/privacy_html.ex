defmodule SpreaderWeb.PrivacyHTML do
  @moduledoc "HTML templates for Privacy Policy pages"

  use SpreaderWeb, :html

  # Looks for templates in lib/spreader_web/templates/privacy_html/
  embed_templates "../templates/privacy_html/*"
end
