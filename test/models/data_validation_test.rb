require "test_helper"

class DataValidationTest < ActiveSupport::TestCase
  test "administrator product data requires meaningful and correctly formatted values" do
    category = Category.new(name: "Validation Products")
    product = Product.new(
      category: category,
      name: "Validated Keyboard",
      description: "",
      sku: "bad sku!",
      price: 0,
      stock_quantity: -1,
      active: true
    )

    assert_not product.valid?
    assert_includes product.errors[:description], "can't be blank"
    assert_includes product.errors[:sku], "must contain only letters, numbers, and single hyphens"
    assert_includes product.errors[:price], "must be greater than 0"
    assert_includes product.errors[:stock_quantity], "must be greater than or equal to 0"
  end

  test "customer contact data validates names phone numbers and Canadian postal codes" do
    province = Province.new(name: "Manitoba", abbreviation: "MB")
    customer = Customer.new(
      province: province,
      first_name: "123",
      last_name: "Customer",
      email: "not-an-email",
      phone: "12345",
      postal_code: "INVALID"
    )

    assert_not customer.valid?
    assert_includes customer.errors[:first_name], "may only contain letters and common name punctuation"
    assert_includes customer.errors[:email], "is invalid"
    assert_includes customer.errors[:phone], "must be a valid North American phone number"
    assert_includes customer.errors[:postal_code], "must be a valid Canadian postal code"
  end

  test "valid customer formatting is normalized before persistence" do
    province = Province.create!(name: "Validation Manitoba", abbreviation: "vm")
    customer = Customer.new(
      province: province,
      first_name: "  Jamie ",
      last_name: "O'Connor",
      email: " JAMIE@example.com ",
      phone: "204-555-0199",
      postal_code: "r3c 1a1"
    )

    assert customer.valid?
    assert_equal "Jamie", customer.first_name
    assert_equal "jamie@example.com", customer.email
    assert_equal "R3C 1A1", customer.postal_code
    assert_equal "VM", province.abbreviation
  end

  test "province tax models reject an HST rate combined with GST or PST" do
    province = Province.new(
      name: "Invalid Combined Tax Province",
      abbreviation: "IC",
      gst_rate: 0.05,
      pst_rate: 0,
      hst_rate: 0.13
    )

    assert_not province.valid?
    assert_includes province.errors[:hst_rate], "cannot be combined with GST or PST"
  end

  test "administrator usernames reject spaces and unsafe punctuation" do
    admin = AdminUser.new(
      username: "invalid admin!",
      email: "validation-admin@example.com",
      password: "password"
    )

    assert_not admin.valid?
    assert_includes admin.errors[:username],
      "may only contain letters, numbers, dots, underscores, and hyphens"
  end
end
