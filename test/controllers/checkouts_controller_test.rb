require "test_helper"

class CheckoutsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @manitoba = Province.create!(
      name: "Manitoba",
      abbreviation: "MB",
      gst_rate: 0.05,
      pst_rate: 0.07,
      hst_rate: 0
    )
    @ontario = Province.create!(
      name: "Ontario",
      abbreviation: "ON",
      gst_rate: 0,
      pst_rate: 0,
      hst_rate: 0.13
    )
    category = Category.create!(name: "Checkout Products")
    @keyboard = Product.create!(
      category: category,
      name: "Checkout Keyboard",
      brand: "Prairie Tech",
      sku: "CHECKOUT-KEY-001",
      price: 100,
      sale_price: 80,
      stock_quantity: 8,
      description: "A sale-priced keyboard used to test checkout invoices.",
      active: true
    )
    @mouse = Product.create!(
      category: category,
      name: "Checkout Mouse",
      brand: "Prairie Tech",
      sku: "CHECKOUT-MOUSE-002",
      price: 40,
      stock_quantity: 6,
      description: "A mouse used to test multi-product checkout invoices.",
      active: true
    )
  end

  test "creates customer order and Manitoba GST PST invoice" do
    post add_cart_item_path(@keyboard), params: { quantity: 2 }
    post add_cart_item_path(@mouse), params: { quantity: 1 }

    get new_checkout_path
    assert_response :success
    assert_select "form.checkout-form[action='#{checkout_path}']"
    assert_select "select[name='customer[province_id]']"
    assert_select "option[value='#{@manitoba.id}']", text: "Manitoba"
    assert_select ".checkout-review-item", count: 2
    assert_select ".checkout-review-total", text: /Subtotal before tax.*\$200\.00/

    assert_difference ["Customer.count", "Order.count"], 1 do
      assert_difference "OrderItem.count", 2 do
        post checkout_path, params: {
          customer: {
            first_name: "Jamie",
            last_name: "Prairie",
            email: "JAMIE@example.com",
            phone: "204-555-0199",
            address: "123 Portage Avenue",
            city: "Winnipeg",
            postal_code: "R3B 2B9",
            province_id: @manitoba.id
          }
        }
      end
    end

    order = Order.order(:id).last
    customer = Customer.order(:id).last
    assert_redirected_to order_path(order)
    assert_equal customer, order.customer
    assert_nil order.user
    assert_equal "jamie@example.com", customer.email
    assert_equal "123 Portage Avenue", customer.address
    assert_equal @manitoba, customer.province
    assert_equal BigDecimal("200.00"), order.subtotal
    assert_equal BigDecimal("10.00"), order.gst_amount
    assert_equal BigDecimal("14.00"), order.pst_amount
    assert_equal BigDecimal("0.00"), order.hst_amount
    assert_equal BigDecimal("224.00"), order.total
    assert_equal 6, @keyboard.reload.stock_quantity
    assert_equal 5, @mouse.reload.stock_quantity

    follow_redirect!
    assert_response :success
    assert_select "h1", text: "Invoice ##{order.id.to_s.rjust(6, '0')}"
    assert_select ".invoice-table tbody tr", count: 2
    assert_select ".invoice-totals", text: /GST \(5%\).*\$10\.00/m
    assert_select ".invoice-totals", text: /Provincial sales tax \(7%\).*\$14\.00/m
    assert_select ".invoice-grand-total", text: /Total.*\$224\.00/m

    get cart_path
    assert_select ".empty-cart", text: /Your cart is empty/
  end

  test "uses Ontario HST and accepts province without street address" do
    post add_cart_item_path(@mouse), params: { quantity: 1 }

    post checkout_path, params: {
      customer: {
        first_name: "Alex",
        last_name: "Ontario",
        email: "alex.ontario@example.com",
        province_id: @ontario.id
      }
    }

    order = Order.order(:id).last
    assert_redirected_to order_path(order)
    assert_equal @ontario, order.customer.province
    assert_nil order.customer.address
    assert_equal "in_store_pickup", order.delivery_method
    assert_equal BigDecimal("0.00"), order.gst_amount
    assert_equal BigDecimal("0.00"), order.pst_amount
    assert_equal BigDecimal("5.20"), order.hst_amount
    assert_equal BigDecimal("45.20"), order.total

    follow_redirect!
    assert_select ".invoice-totals", text: /HST \(13%\).*\$5\.20/m
    assert_select ".invoice-totals", text: /GST/, count: 0
    assert_select ".invoice-totals", text: /Provincial sales tax/, count: 0
  end

  test "keeps cart when customer details are invalid" do
    post add_cart_item_path(@keyboard), params: { quantity: 1 }

    assert_no_difference ["Customer.count", "Order.count", "OrderItem.count"] do
      post checkout_path, params: {
        customer: {
          first_name: "",
          last_name: "Invalid",
          email: "not-an-email",
          province_id: @manitoba.id
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".form-errors"
    assert_select ".checkout-review-item", count: 1

    get cart_path
    assert_select "h2", text: @keyboard.name
  end
end
