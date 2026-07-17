require "test_helper"

class StorefrontTest < ActionDispatch::IntegrationTest
  setup do
    @category = Category.create!(name: "Test Gaming")
    @product = Product.create!(
      category: @category,
      name: "Test Mechanical Keyboard",
      brand: "Test Brand",
      sku: "TEST-KEY-001",
      price: 99.99,
      stock_quantity: 4,
      description: "A complete product description for storefront testing.",
      active: true
    )
    SitePage.create!(slug: "about", title: "About Test Store", body: "About page body.")
    SitePage.create!(slug: "contact", title: "Contact Test Store", body: "Contact page body.")
  end

  test "lists and shows active products" do
    get products_url
    assert_response :success
    assert_select "h3", text: @product.name

    get product_url(@product)
    assert_response :success
    assert_select "h1", text: @product.name
  end

  test "shows editable public pages" do
    get about_url
    assert_response :success
    assert_select "h1", text: "About Test Store"

    get contact_url
    assert_response :success
    assert_select "h1", text: "Contact Test Store"
  end

  test "admin dashboard requires authentication" do
    get admin_root_url

    assert_redirected_to new_admin_user_session_url
  end
end
