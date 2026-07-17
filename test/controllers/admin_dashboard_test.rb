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
    @category = Category.create!(name: "Admin Test", description: "Products used by the admin integration test.")
    @product = Product.create!(
      category: @category,
      name: "Admin Test Product",
      brand: "Prairie Tech",
      sku: "ADMIN-TEST-001",
      description: "A complete product used to verify the administration interface.",
      price: 49.99,
      stock_quantity: 5,
      active: true
    )
    @other_category = Category.create!(name: "Other Admin Category")
    @inactive_product = Product.create!(
      category: @other_category,
      name: "Inactive Admin Product",
      brand: "Prairie Tech",
      sku: "ADMIN-INACTIVE-002",
      description: "A second complete product used to verify administration filters.",
      price: 99.99,
      stock_quantity: 15,
      active: false
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

  test "product filters are limited and filter the collection" do
    get admin_products_path
    assert_response :success
    assert_select "a[href*='.csv']", count: 0
    assert_select "a[href*='.xml']", count: 0
    assert_select "a[href*='.json']", count: 0
    assert_select "select[name='q[category_id_eq]']"
    assert_select "select[name='q[active_eq]']"
    assert_select "input[name='q[price_eq]']"
    assert_select "select[data-search-methods] option[value='price_eq']"
    assert_select "select[data-search-methods] option[value='price_gteq']"
    assert_select "select[data-search-methods] option[value='price_lteq']"
    assert_select "input[name='q[name_contains]']", count: 0
    assert_select "input[name='q[brand_contains]']", count: 0
    assert_select "input[name='q[sku_contains]']", count: 0

    [:csv, :xml, :json].each do |format|
      get admin_products_path(format: format)
      assert_response :unauthorized
    end

    get admin_products_path(q: { category_id_eq: @category.id })
    assert_response :success
    assert_select "tr#product_#{@product.id}"
    assert_select "tr#product_#{@inactive_product.id}", count: 0

    get admin_products_path(q: { active_eq: false })
    assert_response :success
    assert_select "tr#product_#{@inactive_product.id}"
    assert_select "tr#product_#{@product.id}", count: 0

    get admin_products_path(q: { price_lteq: 60 })
    assert_response :success
    assert_select "tr#product_#{@product.id}"
    assert_select "tr#product_#{@inactive_product.id}", count: 0
  end
end
