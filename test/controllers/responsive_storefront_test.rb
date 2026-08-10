require "test_helper"

class ResponsiveStorefrontTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    province = Province.create!(
      name: "Responsive Manitoba",
      abbreviation: "RM",
      gst_rate: 0.05,
      pst_rate: 0.07,
      hst_rate: 0
    )
    @customer = Customer.create!(
      province: province,
      first_name: "Mobile",
      last_name: "Customer",
      username: "mobile_customer",
      email: "mobile-customer@example.com",
      account_registered: true,
      password: "password123",
      password_confirmation: "password123"
    )
    category = Category.create!(name: "Responsive Products")
    @product = Product.create!(
      category: category,
      name: "Responsive Test Laptop",
      brand: "Prairie Tech",
      sku: "RESPONSIVE-001",
      description: "A product used to verify the responsive storefront structure.",
      price: 100,
      stock_quantity: 5,
      active: true
    )
  end

  test "layout provides an accessible collapsible navigation for small screens" do
    get root_path

    assert_response :success
    assert_select "meta[name='viewport'][content='width=device-width,initial-scale=1']"
    assert_select "button.nav-toggle[aria-controls='site-navigation'][aria-expanded='false']"
    assert_select "nav#site-navigation.site-nav[aria-label='Main navigation']"
    assert_select "nav#site-navigation a[href='#{cart_path}'] .cart-count"
  end

  test "cart and checkout retain usable mobile form controls" do
    post add_cart_item_path(@product), params: { quantity: 2 }

    get cart_path
    assert_response :success
    assert_select ".cart-layout[data-session-cart]"
    assert_select "article.cart-item", count: 1
    assert_select "input[type='number'][min='1'][max='5']"
    assert_select "button.cart-remove-button", text: "Remove"
    assert_select ".cart-summary a.checkout-button[href='#{new_checkout_path}']"

    get new_checkout_path
    assert_response :success
    assert_select ".checkout-layout .checkout-form-panel"
    assert_select ".checkout-layout aside.checkout-review"
    assert_select "select[name='customer[province_id]'][required]"
    assert_select "input.checkout-submit[value='Place order and view invoice']"
  end

  test "mobile invoice cells include labels when the table becomes stacked cards" do
    order = @customer.orders.create!(
      status: :paid,
      delivery_method: :shipping,
      subtotal: 200,
      gst_amount: 10,
      pst_amount: 14,
      hst_amount: 0,
      delivery_fee: 0,
      total: 224,
      recipient_name: "Mobile Customer",
      province_name: @customer.province.name,
      gst_rate: 0.05,
      pst_rate: 0.07,
      hst_rate: 0,
      paid_at: Time.current
    )
    order.order_items.create!(
      product: @product,
      product_name: @product.name,
      sku: @product.sku,
      quantity: 2,
      unit_price: 100,
      line_total: 200
    )
    sign_in @customer

    get order_path(order)

    assert_response :success
    %w[Product SKU Quantity].each do |label|
      assert_select ".invoice-table td[data-label='#{label}']"
    end
    assert_select ".invoice-table td[data-label='Unit price']"
    assert_select ".invoice-table td[data-label='Line total']"
  end

  test "stylesheet defines tablet mobile and narrow-phone reconfiguration" do
    stylesheet = Rails.root.join("app/assets/stylesheets/application.css").read

    assert_includes stylesheet, "@media (max-width: 1020px)"
    assert_includes stylesheet, "@media (max-width: 900px)"
    assert_includes stylesheet, "@media (max-width: 640px)"
    assert_includes stylesheet, "@media (max-width: 390px)"
    assert_includes stylesheet, ".nav-ready .site-nav:not(.is-open)"
    assert_includes stylesheet, ".invoice-table td::before"
  end
end
