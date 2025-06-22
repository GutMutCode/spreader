defmodule SpreaderWeb.Error.ErrorHTMLTest do
  use SpreaderWeb.ConnCase, async: true

  # Bring render_to_string/4 for testing custom views
  import Phoenix.Template

  test "renders 404.html" do
    assert is_binary(render_to_string(SpreaderWeb.Error.ErrorHTML, "404", "html", []))
  end

  test "renders 500.html" do
    assert is_binary(render_to_string(SpreaderWeb.Error.ErrorHTML, "500", "html", []))
  end
end
