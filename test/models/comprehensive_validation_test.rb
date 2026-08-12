require "test_helper"

class ComprehensiveValidationTest < ActiveSupport::TestCase
  setup do
    @province = Province.create!(
      name: "Comprehensive Validation Province",
      abbreviation: "CV",
      gst_rate: 0.05,
      pst_rate: 0.07,
      hst_rate: 0
    )
    @category = Category.create!(
      name: "Comprehensive Validation Products",
      description: "Products used to exercise model validations."
    )
    @product = Product.create!(
      category: @category,
      name: "Validation Laptop",
      brand: "Prairie Tech",
      sku: "VALIDATION-001",
      description: "A real product description for comprehensive model validation.",
      price: 100,
      stock_quantity: 3,
      active: true
    )
  end

  test "legacy user contact and password data is correctly formatted" do
    user = User.new(
      province: @province,
      first_name: "123",
      last_name: "Customer",
      email: "customer@example",
      phone: "12345",
      postal_code: "INVALID",
      password: "short",
      password_confirmation: "short"
    )

    assert_not user.valid?
    assert_includes user.errors[:first_name], "may only contain letters and common name punctuation"
    assert_includes user.errors[:email], "must be a complete email address, such as name@example.com"
    assert_includes user.errors[:phone], "must be a valid North American phone number"
    assert_includes user.errors[:postal_code], "must be a valid Canadian postal code"
    assert_includes user.errors[:password], "is too short (minimum is 8 characters)"
  end

  test "each user has one cart and cart quantities cannot exceed stock" do
    user = valid_user
    cart = Cart.create!(user: user)
    duplicate_cart = Cart.new(user: user)
    oversized_item = CartItem.new(cart: cart, product: @product, quantity: 4)

    assert_not duplicate_cart.valid?
    assert_includes duplicate_cart.errors[:user_id], "has already been taken"
    assert_not oversized_item.valid?
    assert_includes oversized_item.errors[:quantity], "cannot exceed the available stock of 3"
  end

  test "delivery and repair pickups require a complete Canadian address" do
    pickup = PickupRequest.new(
      user: valid_user,
      pickup_type: :repair_pickup,
      scheduled_at: 1.day.from_now,
      postal_code: "invalid"
    )

    assert_not pickup.valid?
    assert_includes pickup.errors[:address], "is required for delivery or repair pickup"
    assert_includes pickup.errors[:city], "is required for delivery or repair pickup"
    assert_includes pickup.errors[:postal_code], "must be a valid Canadian postal code"
  end

  test "repair descriptions and estimates are constrained" do
    repair = RepairRequest.new(
      pickup_request: PickupRequest.new,
      device_type: "Laptop",
      problem_description: "x" * 5_001,
      estimated_price: -1
    )

    assert_not repair.valid?
    assert_includes repair.errors[:problem_description], "is too long (maximum is 5000 characters)"
    assert_includes repair.errors[:estimated_price], "must be greater than or equal to 0"
  end

  test "order tax snapshots and grand totals must be internally consistent" do
    order = Order.new(
      customer: valid_customer,
      delivery_method: :shipping,
      recipient_name: "Validation Customer",
      province_name: @province.name,
      subtotal: 100,
      gst_amount: 5,
      pst_amount: 7,
      hst_amount: 13,
      delivery_fee: 0,
      total: 110,
      gst_rate: 0.05,
      pst_rate: 0.07,
      hst_rate: 0.13
    )

    assert_not order.valid?
    assert_includes order.errors[:total], "must equal subtotal, taxes, and delivery fee"
    assert_includes order.errors[:hst_rate], "cannot be combined with GST or PST"
  end

  test "order item snapshots require a valid SKU and calculated line total" do
    item = OrderItem.new(
      order: valid_order,
      product: @product,
      product_name: @product.name,
      sku: "bad sku!",
      quantity: 2,
      unit_price: 100,
      line_total: 150
    )

    assert_not item.valid?
    assert_includes item.errors[:sku], "must contain only letters, numbers, and single hyphens"
    assert_includes item.errors[:line_total], "must equal quantity multiplied by unit price"
  end

  test "administrator emails must be complete addresses" do
    admin = AdminUser.new(
      username: "validation_admin",
      email: "admin@example",
      password: "password123",
      password_confirmation: "password123"
    )

    assert_not admin.valid?
    assert_includes admin.errors[:email], "must be a complete email address, such as name@example.com"
  end

  private

  def valid_user
    User.create!(
      province: @province,
      first_name: "Legacy",
      last_name: "Customer",
      email: "legacy-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  def valid_customer
    Customer.create!(
      province: @province,
      first_name: "Validation",
      last_name: "Customer",
      email: "customer-#{SecureRandom.hex(4)}@example.com"
    )
  end

  def valid_order
    Order.new(
      customer: valid_customer,
      delivery_method: :shipping,
      recipient_name: "Validation Customer",
      province_name: @province.name,
      subtotal: 100,
      gst_amount: 5,
      pst_amount: 7,
      hst_amount: 0,
      delivery_fee: 0,
      total: 112,
      gst_rate: 0.05,
      pst_rate: 0.07,
      hst_rate: 0
    )
  end
end
