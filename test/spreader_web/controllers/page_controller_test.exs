defmodule SpreaderWeb.PageControllerTest do
  use SpreaderWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
  end
end
