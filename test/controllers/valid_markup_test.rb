require "test_helper"
require "nokogiri"

class ValidMarkupTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @province = Province.create!(
      name: "Markup Manitoba",
      abbreviation: "MM",
      gst_rate: 0.05,
      pst_rate: 0.07,
      hst_rate: 0
    )
    @category = Category.create!(
      name: "Markup Products",
      description: "Products used to validate rendered HTML pages."
    )
    @product = Product.create!(
      category: @category,
      name: "Markup Test Laptop",
      brand: "Prairie Tech",
      sku: "MARKUP-001",
      description: "A complete product description for HTML validation.",
      price: 999.99,
      stock_quantity: 5,
      active: true
    )
    Product.create!(
      category: @category,
      name: "Markup Test Mouse",
      brand: "Prairie Tech",
      sku: "MARKUP-002",
      description: "A second product that detects repeated card IDs.",
      price: 49.99,
      stock_quantity: 8,
      active: true
    )
    @customer = Customer.create!(
      province: @province,
      first_name: "Markup",
      last_name: "Customer",
      username: "markup_customer",
      email: "markup.customer@example.com",
      account_registered: true,
      password: "password123",
      password_confirmation: "password123"
    )
    @order = @customer.orders.create!(
      status: :paid,
      delivery_method: :shipping,
      subtotal: 999.99,
      gst_amount: 50.00,
      pst_amount: 70.00,
      hst_amount: 0,
      delivery_fee: 0,
      total: 1_119.99,
      recipient_name: "Markup Customer",
      province_name: @province.name,
      gst_rate: 0.05,
      pst_rate: 0.07,
      hst_rate: 0,
      paid_at: Time.current
    )
    @order.order_items.create!(
      product: @product,
      product_name: @product.name,
      sku: @product.sku,
      quantity: 1,
      unit_price: 999.99,
      line_total: 999.99
    )
    SitePage.create!(slug: "about", title: "About Markup Store", body: "Valid about-page content.")
    SitePage.create!(slug: "contact", title: "Contact Markup Store", body: "Valid contact-page content.")
  end

  test "all storefront page types render valid HTML5 document structures" do
    guest_paths = [
      root_path,
      products_path,
      product_path(@product),
      categories_path,
      category_path(@category),
      about_path,
      contact_path,
      cart_path,
      new_customer_session_path,
      new_customer_registration_path
    ]

    guest_paths.each { |path| assert_valid_html_document(path) }

    post add_cart_item_path(@product), params: { quantity: 1 }
    assert_redirected_to cart_path
    assert_valid_html_document(cart_path)
    assert_valid_html_document(new_checkout_path)

    sign_in @customer
    [root_path, orders_path, order_path(@order), edit_customer_registration_path].each do |path|
      assert_valid_html_document(path)
    end
  end

  test "administrator page types render valid HTML5 document structures" do
    admin = AdminUser.create!(
      username: "markup_admin",
      email: "markup.admin@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    sign_in admin

    [
      admin_root_path,
      admin_products_path,
      admin_product_path(@product),
      edit_admin_product_path(@product),
      admin_orders_path,
      admin_order_path(@order),
      admin_provinces_path,
      admin_site_pages_path,
      admin_admin_users_path
    ].each { |path| assert_valid_html_document(path) }
  end

  private

  def assert_valid_html_document(path)
    get path
    assert_response :success, "Expected #{path} to render successfully"

    document = Nokogiri::HTML5.parse(response.body, max_errors: -1)
    parser_errors = document.errors.map(&:message)
    assert_empty parser_errors, "HTML5 parser errors on #{path}:\n#{parser_errors.join("\n")}"
    assert response.body.match?(/\A<!DOCTYPE html>/i), "Missing HTML5 doctype on #{path}"
    assert_equal "en", document.at_css("html")&.[]("lang"), "Missing document language on #{path}"
    ids = document.css("[id]").filter_map { |node| node["id"].presence }
    duplicate_ids = ids.tally.select { |_id, count| count > 1 }.keys
    assert_empty duplicate_ids, "Duplicate IDs on #{path}: #{duplicate_ids.join(", ")}"
    assert_empty document.css("form form, a a, button a, a button"), "Invalid interactive nesting on #{path}"
    assert_empty document.css("img:not([alt])"), "Images without alt attributes on #{path}"
    assert_empty document.css('[aria-current=""]'), "Empty aria-current value on #{path}"
    assert_empty document.css('input[type="hidden"][autocomplete]'),
      "Hidden inputs with invalid autocomplete attributes on #{path}"
  end
end
