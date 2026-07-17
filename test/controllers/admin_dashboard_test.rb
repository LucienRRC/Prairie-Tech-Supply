require "test_helper"

class AdminDashboardTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = AdminUser.create!(
      username: "dashboard_admin",
      email: "dashboard@example.com",
      password: "password",
      password_confirmation: "password"
    )
    sign_in @admin
  end

  test "authenticated administrator can access management pages" do
    get admin_root_path
    assert_response :success
    assert_select "h2", text: "Prairie Tech Supply"

    get admin_products_path
    assert_response :success

    get admin_site_pages_path
    assert_response :success
  end
end
