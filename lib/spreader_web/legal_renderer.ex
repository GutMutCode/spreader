defmodule SpreaderWeb.LegalRenderer do
  @moduledoc """
  Converts the structured JSON versions of Terms of Service and Privacy Policy
  into HTML snippets that can be embedded inside HEEx templates.

  • The JSON is loaded **at compile-time** for performance.
  • Only a subset of the schema (text, heading, list) is handled; other node
    types are ignored gracefully.
  • The output is an HTML-safe string that you can insert with `Phoenix.HTML.raw/1`.
  """

  import Phoenix.HTML, only: [html_escape: 1, safe_to_string: 1, raw: 1]

  @external_resource terms_path = Path.expand("../../terms_of_service.json", __DIR__)
  @external_resource privacy_path = Path.expand("../../privacy_policy.json", __DIR__)

  @terms_data terms_path |> File.read!() |> Jason.decode!()
  @privacy_data privacy_path |> File.read!() |> Jason.decode!()

  # Public API --------------------------------------------------------------

  def render_terms_html(locale) when locale in ["ko", "en"] do
    doc = locale_data(@terms_data, locale)
    doc |> nodes_to_html() |> safe()
  end

  def render_privacy_html(locale) when locale in ["ko", "en"] do
    doc = locale_data(@privacy_data, locale)
    doc |> nodes_to_html() |> safe()
  end

  # Helpers ----------------------------------------------------------------

  defp locale_data(%{"document" => doc} = _root, _locale), do: doc

  # Recursively transform node maps → HTML string
  defp nodes_to_html(nil), do: ""
  defp nodes_to_html(list) when is_list(list), do: Enum.map_join(list, "", &nodes_to_html/1)

  defp nodes_to_html(%{"type" => "text", "value" => v}), do: "<p>#{esc(v)}</p>"
  defp nodes_to_html(%{"type" => "heading", "value" => v}), do: "<h2>#{esc(v)}</h2>"

  defp nodes_to_html(%{"type" => "list", "items" => items}) do
    items_html = items |> Enum.map_join("", fn %{"text" => v} -> "<li>#{esc(v)}</li>" end)
    "<ul>#{items_html}</ul>"
  end

  # Fallback: recurse into maps with nested content fields
  defp nodes_to_html(%{"content" => content} = _m), do: nodes_to_html(content)
  defp nodes_to_html(%{"chapters" => chapters}), do: nodes_to_html(chapters)
  defp nodes_to_html(%{"sections" => sections}), do: nodes_to_html(sections)
  defp nodes_to_html(_), do: "" # ignore unsupported nodes

  defp safe(html), do: raw(html)
  defp esc(v), do: v |> html_escape() |> safe_to_string()
end
