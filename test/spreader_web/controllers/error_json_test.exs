defmodule SpreaderWeb.ErrorJSONTest do
  use SpreaderWeb.ConnCase, async: true

  alias SpreaderWeb.Error.ErrorJSON

  test "renders 404" do
    assert ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
