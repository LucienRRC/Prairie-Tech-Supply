require "test_helper"

class CustomerOrderHistoryTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @province = Province.create!(
      name: "History Manitoba",
      abbreviation: "HM",
      gst_rate: 0.05,
      pst_rate: 0.07,
      hst_rate: 0
    )
    @customer = create_customer("history_customer", "history@example.com")
    @other_customer = create_customer("other_history_customer", "other-history@example.com")
    category = Category.create!(name: "Order History Products")
    @keyboard = create_product(category, "History Keyboard", "HISTORY-KEY-001", 100)
    @mouse = create_product(category, "History Mouse", "HISTORY-MOUSE-002", 40)
    @order = create_order(@customer, @keyboard, quantity: 2, subtotal: 200, gst: 10, pst: 14, total: 224)
    @older_order = create_order(@customer, @mouse, quantity: 1, subtotal: 40, gst: 2, pst: 2.8, total: 44.8)
    @other_order = create_order(@other_customer, @mouse, quantity: 3, subtotal: 120, gst: 6, pst: 8.4, total: 134.4)
  end

  test "signed in customer reviews only their own orders with products taxes and totals" do
    sign_in @customer

    get orders_path

    assert_response :success
    assert_select ".order-history-card", count: 2
    assert_select ".order-history-products", text: /2.*History Keyboard.*\$200\.00/m
    assert_select ".order-history-products", text: /1.*History Mouse.*\$40\.00/m
    assert_select ".order-history-taxes", text: /GST.*\$10\.00.*Provincial tax.*\$14\.00.*HST.*\$0\.00/m
    assert_select ".order-history-card", text: /Grand total.*\$224\.00/m
    assert_select "a[href='#{order_path(@order)}']", text: "View invoice"
    assert_select ".order-history-card", text: /\$134\.40/, count: 0

    get order_path(@order)
    assert_response :success
    assert_select "a[href='#{orders_path}']", text: "Back to order history"

    get order_path(@other_order)
    assert_redirected_to root_path
  end

  test "order history requires a customer login" do
    get orders_path

    assert_redirected_to new_customer_session_path
  end

  private

  def create_customer(username, email)
    Customer.create!(
      province: @province,
      first_name: "Order",
      last_name: "Customer",
      username: username,
      email: email,
      account_registered: true,
      password: "password123",
      password_confirmation: "password123"
    )
  end

  def create_product(category, name, sku, price)
    Product.create!(
      category: category,
      name: name,
      brand: "Prairie Tech",
      sku: sku,
      description: "A complete product used to verify the order history interface.",
      price: price,
      stock_quantity: 10,
      active: true
    )
  end

  def create_order(customer, product, quantity:, subtotal:, gst:, pst:, total:)
    order = Order.create!(
      customer: customer,
      status: :shipped,
      delivery_method: :in_store_pickup,
      subtotal: subtotal,
      gst_amount: gst,
      pst_amount: pst,
      hst_amount: 0,
      delivery_fee: 0,
      total: total,
      recipient_name: "#{customer.first_name} #{customer.last_name}",
      province_name: @province.name,
      gst_rate: 0.05,
      pst_rate: 0.07,
      hst_rate: 0
    )
    order.order_items.create!(
      product: product,
      product_name: product.name,
      sku: product.sku,
      quantity: quantity,
      unit_price: product.price,
      line_total: subtotal
    )
    order
  end
end

class AdminOrderHistoryTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    admin = AdminUser.create!(
      username: "order_history_admin",
      email: "orders-admin@example.com",
      password: "password",
      password_confirmation: "password"
    )
    province = Province.create!(
      name: "Admin History Ontario",
      abbreviation: "AO",
      gst_rate: 0,
      pst_rate: 0,
      hst_rate: 0.13
    )
    customer = Customer.create!(
      province: province,
      first_name: "Admin",
      last_name: "Order Customer",
      username: "admin_order_customer",
      email: "admin-order-customer@example.com",
      account_registered: true,
      password: "password123",
      password_confirmation: "password123"
    )
    category = Category.create!(name: "Admin Order Products")
    product = Product.create!(
      category: category,
      name: "Admin History Laptop",
      brand: "Prairie Tech",
      sku: "ADMIN-HISTORY-001",
      description: "A laptop used to verify inline administrator order details.",
      price: 1000,
      stock_quantity: 5,
      active: true
    )
    @order = Order.create!(
      customer: customer,
      status: :paid,
      delivery_method: :shipping,
      subtotal: 2000,
      gst_amount: 0,
      pst_amount: 0,
      hst_amount: 260,
      delivery_fee: 0,
      total: 2260,
      recipient_name: "Admin Order Customer",
      province_name: province.name,
      gst_rate: 0,
      pst_rate: 0,
      hst_rate: 0.13
    )
    @order.order_items.create!(
      product: product,
      product_name: product.name,
      sku: product.sku,
      quantity: 2,
      unit_price: 1000,
      line_total: 2000
    )
    sign_in admin
  end

  test "administrator sees customer products taxes and total together on order list" do
    get admin_orders_path

    assert_response :success
    assert_select "tr#order_#{@order.id}", text: /Admin Order Customer/m
    assert_select "tr#order_#{@order.id}", text: /admin-order-customer@example\.com/m
    assert_select "tr#order_#{@order.id} .admin-order-products", text: /2 x Admin History Laptop.*\$2,000\.00/m
    assert_select "tr#order_#{@order.id} .admin-order-taxes", text: /GST.*\$0\.00.*Provincial.*\$0\.00.*HST.*\$260\.00/m
    assert_select "tr#order_#{@order.id}", text: /\$2,260\.00/m
    assert_select "a[href*='.csv'], a[href*='.xml'], a[href*='.json']", count: 0

    get admin_order_path(@order)
    assert_response :success
    assert_select "h3", text: "Products ordered"
    assert_select "table", text: /Admin History Laptop.*2.*\$1,000\.00.*\$2,000\.00/m
  end
end
