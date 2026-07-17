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
    category = Category.create!(name: "Admin Test", description: "Products used by the admin integration test.")
    @product = Product.create!(
      category: category,
      name: "Admin Test Product",
      brand: "Prairie Tech",
      sku: "ADMIN-TEST-001",
      description: "A complete product used to verify the administration interface.",
      price: 49.99,
      stock_quantity: 5,
      active: true
    )
    @product.image.attach(
      io: File.open(Rails.root.join("app/assets/images/computer-technology.jpg"), "rb"),
      filename: "computer-technology.jpg",
      content_type: "image/jpeg"
    )
    sign_in @admin
  end

  test "authenticated administrator can access management pages" do
    get admin_root_path
    assert_response :success
    assert_select "h2", text: "Prairie Tech Supply"

    get admin_products_path
    assert_response :success
    assert_select "img.admin-product-thumb[alt='Admin Test Product']"

    get edit_admin_product_path(@product)
    assert_response :success
    assert_select "img.admin-product-preview"

    get admin_site_pages_path
    assert_response :success
  end
end
