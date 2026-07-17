require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "shows the storefront home page" do
    get root_url

    assert_response :success
    assert_select "h1", "Technology that works for Winnipeg."
  end
end
