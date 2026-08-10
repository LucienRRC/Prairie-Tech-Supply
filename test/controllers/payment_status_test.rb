require "test_helper"

class PaymentStatusTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @previous_secret_key = Rails.application.config.x.stripe.secret_key
    @previous_webhook_secret = Rails.application.config.x.stripe.webhook_secret
    Rails.application.config.x.stripe.secret_key = "sk_test_prairie_tech"
    Rails.application.config.x.stripe.webhook_secret = "whsec_prairie_tech"

    province = Province.create!(
      name: "Payment Test Province",
      abbreviation: "PT",
      gst_rate: 0.05,
      pst_rate: 0.07,
      hst_rate: 0
    )
    @customer = Customer.create!(
      province: province,
      first_name: "Payment",
      last_name: "Customer",
      username: "payment_status_customer",
      email: "payment-status@example.com",
      account_registered: true,
      password: "password123",
      password_confirmation: "password123"
    )
    category = Category.create!(name: "Payment Status Products")
    @product = Product.create!(
      category: category,
      name: "Webhook Test Laptop",
      brand: "Prairie Tech",
      sku: "PAYMENT-WEBHOOK-001",
      description: "A product used to verify Stripe payment status transitions.",
      price: 100,
      stock_quantity: 8,
      active: true
    )
    @order = create_order
  end

  teardown do
    Rails.application.config.x.stripe.secret_key = @previous_secret_key
    Rails.application.config.x.stripe.webhook_secret = @previous_webhook_secret
  end

  test "verified Stripe webhook changes a new order to paid only once" do
    event = stripe_event("checkout.session.completed", payment_status: "paid")

    Stripe::Webhook.stub(:construct_event, event) do
      post stripe_webhook_path,
        params: "{}",
        headers: { "Stripe-Signature" => "valid-test-signature", "Content-Type" => "application/json" }
      assert_response :success

      paid_at = @order.reload.paid_at
      assert @order.paid?
      assert_equal "pi_test_order_#{@order.id}", @order.stripe_payment_intent_id
      assert_not_nil paid_at

      post stripe_webhook_path,
        params: "{}",
        headers: { "Stripe-Signature" => "valid-test-signature", "Content-Type" => "application/json" }
      assert_response :success
      assert_equal paid_at, @order.reload.paid_at
    end
  end

  test "Stripe success return confirms payment while a mismatched return cannot" do
    sign_in @customer
    paid_session = stripe_event("checkout.session.completed", payment_status: "paid").data.object

    StripeCheckoutSession.stub(:retrieve, paid_session) do
      get payment_success_path(@order), params: { session_id: @order.stripe_checkout_session_id }
    end
    assert_redirected_to order_path(@order)
    assert @order.reload.paid?

    other_order = create_order
    StripeCheckoutSession.stub(:retrieve, ->(*) { flunk "Stripe must not be called for a mismatched session" }) do
      get payment_success_path(other_order), params: { session_id: "cs_wrong" }
    end
    assert_redirected_to order_path(other_order)
    assert other_order.reload.new_order?
  end

  test "webhook rejects unpaid or mismatched payment confirmations" do
    unpaid_event = stripe_event("checkout.session.completed", payment_status: "unpaid")
    Stripe::Webhook.stub(:construct_event, unpaid_event) do
      post stripe_webhook_path, params: "{}", headers: { "Stripe-Signature" => "valid" }
      assert_response :unprocessable_entity
    end
    assert @order.reload.new_order?

    wrong_amount_event = stripe_event("checkout.session.completed", payment_status: "paid", amount_total: 1)
    Stripe::Webhook.stub(:construct_event, wrong_amount_event) do
      post stripe_webhook_path, params: "{}", headers: { "Stripe-Signature" => "valid" }
      assert_response :unprocessable_entity
    end
    assert @order.reload.new_order?
  end

  test "webhook rejects an invalid Stripe signature" do
    signature_error = Stripe::SignatureVerificationError.new("Invalid signature", "invalid")
    verifier = ->(*) { raise signature_error }

    Stripe::Webhook.stub(:construct_event, verifier) do
      post stripe_webhook_path, params: "{}", headers: { "Stripe-Signature" => "invalid" }
    end

    assert_response :bad_request
    assert @order.reload.new_order?
  end

  test "expired Stripe session cancels new order and restores reserved inventory once" do
    event = stripe_event("checkout.session.expired", payment_status: "unpaid")

    Stripe::Webhook.stub(:construct_event, event) do
      assert_difference -> { @product.reload.stock_quantity }, 2 do
        post stripe_webhook_path, params: "{}", headers: { "Stripe-Signature" => "valid" }
      end
      assert_response :success
      assert @order.reload.cancelled?

      assert_no_difference -> { @product.reload.stock_quantity } do
        post stripe_webhook_path, params: "{}", headers: { "Stripe-Signature" => "valid" }
      end
    end
  end

  test "administrator can ship only a paid order" do
    admin = AdminUser.create!(
      username: "shipping_admin",
      email: "shipping-admin@example.com",
      password: "password",
      password_confirmation: "password"
    )
    sign_in admin

    patch mark_shipped_admin_order_path(@order)
    assert_redirected_to admin_order_path(@order)
    assert @order.reload.new_order?

    @order.update!(status: :paid, paid_at: Time.current)
    get admin_order_path(@order)
    assert_response :success
    assert_select "a[href='#{mark_shipped_admin_order_path(@order)}']", text: "Mark as shipped"

    patch mark_shipped_admin_order_path(@order)
    assert_redirected_to admin_order_path(@order)
    assert @order.reload.shipped?
    assert_not_nil @order.shipped_at

    get admin_order_path(@order)
    assert_response :success
    assert_select "a", text: "Mark as shipped", count: 0
  end

  test "Stripe checkout sends products taxes and order metadata in Canadian dollars" do
    captured_params = nil
    captured_options = nil
    creator = lambda do |params, options|
      captured_params = params
      captured_options = options
      Stripe::Checkout::Session.construct_from(id: "cs_created", url: "https://checkout.stripe.test")
    end

    Stripe::Checkout::Session.stub(:create, creator) do
      StripeCheckoutSession.create(
        order: @order,
        success_url: "http://example.com/success",
        cancel_url: "http://example.com/cancel"
      )
    end

    assert_equal "payment", captured_params[:mode]
    assert_equal @order.id.to_s, captured_params[:metadata][:order_id]
    assert_equal "cad", captured_params[:line_items].first[:price_data][:currency]
    assert_equal 10000, captured_params[:line_items].first[:price_data][:unit_amount]
    assert_equal ["Webhook Test Laptop", "GST", "PST / QST"],
      captured_params[:line_items].map { |item| item[:price_data][:product_data][:name] }
    assert_equal "prairie-tech-order-#{@order.id}", captured_options[:idempotency_key]
  end

  private

  def create_order
    order = Order.create!(
      customer: @customer,
      status: :new_order,
      delivery_method: :shipping,
      subtotal: 200,
      gst_amount: 10,
      pst_amount: 14,
      hst_amount: 0,
      delivery_fee: 0,
      total: 224,
      recipient_name: "Payment Customer",
      province_name: @customer.province.name,
      gst_rate: 0.05,
      pst_rate: 0.07,
      hst_rate: 0,
      stripe_checkout_session_id: "cs_test_order_#{Order.maximum(:id).to_i + 1}"
    )
    order.order_items.create!(
      product: @product,
      product_name: @product.name,
      sku: @product.sku,
      quantity: 2,
      unit_price: 100,
      line_total: 200
    )
    order
  end

  def stripe_event(type, payment_status:, amount_total: 22_400)
    Stripe::Event.construct_from(
      id: "evt_test_#{type.tr('.', '_')}",
      type: type,
      data: {
        object: {
          id: @order.stripe_checkout_session_id,
          payment_status: payment_status,
          payment_intent: "pi_test_order_#{@order.id}",
          currency: "cad",
          amount_total: amount_total,
          metadata: { order_id: @order.id.to_s }
        }
      }
    )
  end
end
