defmodule ArneWeb.ErrorJSONTest do
  use ArneWeb.ConnCase, async: true

  test "renders 404" do
    assert ArneWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert ArneWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
